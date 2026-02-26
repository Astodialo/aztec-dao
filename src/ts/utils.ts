import { createLogger } from "@aztec/aztec.js/log";
import { AztecAddress } from "@aztec/aztec.js/addresses";
import { type Wallet } from "@aztec/aztec.js/wallet";
import { Fr } from "@aztec/aztec.js/fields";
import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";
import { registerInitialLocalNetworkAccountsInWallet } from "@aztec/wallets/testing";
import { EmbeddedWallet } from "@aztec/wallets/embedded";
import { PublicKeys } from "@aztec/stdlib/keys";
import { Contract, DeployOptions } from "@aztec/aztec.js/contracts";

import {
  TreasuryContract,
  TreasuryContractArtifact,
} from "../artifacts/Treasury.js";
import {
  MembersContract,
  MembersContractArtifact,
} from "../artifacts/Members.js";
import {
  GovernanceContract,
  GovernanceContractArtifact,
} from "../artifacts/Governance.js";
import { expect } from "vitest";
import { TokenContract, TokenContractArtifact } from "../artifacts/Token.js";
import { NFTContract, NFTContractArtifact } from "../artifacts/NFT.js";

export const logger = createLogger("aztec:aztec-standards");

import { randomBytes } from "node:crypto";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { rmSync } from "node:fs";
import { getPXEConfig } from "@aztec/pxe/config";
import { Barretenberg } from "@aztec/bb.js";

/** Default port for Aztec local network. */
export const LOCAL_NETWORK_DEFAULT_PORT = 8080;
export const DEFAULT_NODE_URL = `http://localhost:${LOCAL_NETWORK_DEFAULT_PORT}`;

/** Returns the Aztec node URL. Reads NODE_URL from env; defaults to localhost:8080. */
export function getNodeUrl(): string {
  return process.env.NODE_URL ?? DEFAULT_NODE_URL;
}

const node = createAztecNodeClient(getNodeUrl());
await waitForNode(node);
const config = getPXEConfig();

/**
 * Setup the node, wallet and accounts.
 * Lets createPXE handle store creation and l1Contracts fetching internally.
 * @param proverEnabled - optional - Whether to enable the prover, used for benchmarking.
 * @returns The node, wallet, accounts, and a cleanup function.
 */
export const setupTestSuite = async (proverEnabled: boolean = false) => {
  // Reset Barretenberg singleton so a fresh socket is created. Needed when aztec-benchmark's
  // cleanup destroys all sockets (including the prover's), causing EPIPE on the next benchmark.
  if (proverEnabled) {
    await Barretenberg.destroySingleton();
  }

  const dataDirectory = join(
    tmpdir(),
    `aztec-standards-${randomBytes(8).toString("hex")}`,
  );
  const pxeConfig = { ...config, dataDirectory, proverEnabled };

  const wallet: EmbeddedWallet = await EmbeddedWallet.create(node, {
    pxeConfig,
  });

  const accounts: AztecAddress[] =
    await registerInitialLocalNetworkAccountsInWallet(wallet);

  const cleanup = async () => {
    await wallet.stop();
    try {
      rmSync(dataDirectory, { recursive: true, force: true });
    } catch {
      // ignore cleanup errors
    }
  };

  return {
    node,
    wallet,
    accounts,
    cleanup,
  };
};

export async function deployTreasury(
  publicKeys: PublicKeys,
  wallet: Wallet,
  deployer: AztecAddress,
  salt: Fr = Fr.random(),
  gov_address: AztecAddress,
  secretKey?: Fr,
): Promise<TreasuryContract> {

  const deployment = await TreasuryContract.deployWithPublicKeys(
    publicKeys,
    wallet,
    gov_address,
  );

  if (secretKey) {
    const instance = await deployment.getInstance();
    await wallet.registerContract(
      instance,
      TreasuryContractArtifact,
      secretKey,
    );
  }

  const { contract } = await deployment.send({
    contractAddressSalt: salt,
    universalDeploy: true,
    from: deployer,
    wait: { returnReceipt: true },
  });
  return contract as TreasuryContract;
}

export async function deployMembers(
  publicKeys: PublicKeys,
  wallet: Wallet,
  deployer: AztecAddress,
  salt: Fr = Fr.random(),
  gov_address: AztecAddress,
  captain: AztecAddress,
  secretKey?: Fr,
): Promise<MembersContract> {
  const deployment = await MembersContract.deployWithPublicKeys(
    publicKeys,
    wallet,
    gov_address,
    captain,
    2,
    2,
    2,
    captain,
    2,
    0n,
    captain,
  );

  const instance = await deployment.getInstance();
  await wallet.registerContract(instance, MembersContractArtifact, secretKey);

  const { contract } = await deployment.send({
    contractAddressSalt: salt,
    universalDeploy: true,
    from: deployer,
    wait: { returnReceipt: true },
  });
  return contract as MembersContract;
}

export async function deployGovernance(
  publicKeys: PublicKeys,
  wallet: Wallet,
  deployer: AztecAddress,
  salt: Fr = Fr.random(),
  secretKey?: Fr,
): Promise<GovernanceContract> {
  const deployment = GovernanceContract.deployWithPublicKeys(
    publicKeys,
    wallet,
  );

  if (secretKey) {
    const instance = await deployment.getInstance();
    await wallet.registerContract(
      instance,
      GovernanceContractArtifact,
      secretKey,
    );
  }

  const { contract } = await deployment.send({
    contractAddressSalt: salt,
    universalDeploy: true,
    from: deployer,
    wait: { returnReceipt: true },
  });

  return contract as GovernanceContract;
}

// --- Token Utils ---
export const expectUintNote = (
  note: { items: Fr[] },
  amount: bigint,
  _owner: AztecAddress,
) => {
  expect(note.items[0]).toEqual(new Fr(amount));
};

// Maximum value for a u128 (2**128 - 1)
export const MAX_U128_VALUE = 340282366920938463463374607431768211455n;

// --- Token Utils ---

export const expectTokenBalances = async (
  token: TokenContract,
  address: AztecAddress,
  publicBalance: bigint | number | Fr,
  privateBalance: bigint | number | Fr,
  caller?: AztecAddress,
) => {
  const aztecAddress = address instanceof AztecAddress ? address : address;
  logger.info('checking balances for', aztecAddress.toString());
  // We can't use an account that is not in the wallet to simulate the balances, so we use the caller if provided.
  const from = caller ? caller : aztecAddress;

  // Helper to cast to bigint if not already
  const toBigInt = (val: bigint | number | Fr) => {
    if (typeof val === 'bigint') return val;
    if (typeof val === 'number') return BigInt(val);
    if (val instanceof Fr) return val.toBigInt();
    throw new Error('Unsupported type for balance');
  };

  expect(await token.methods.balance_of_public(aztecAddress).simulate({ from })).toBe(toBigInt(publicBalance));
  expect(await token.methods.balance_of_private(aztecAddress).simulate({ from })).toBe(toBigInt(privateBalance));
};

export const AMOUNT = 1000n;
export const wad = (n: number = 1) => AMOUNT * BigInt(n);

/**
 * Deploys the Token contract with a specified minter.
 * @param wallet - The wallet to deploy the contract with.
 * @param deployer - The account to deploy the contract with.
 * @returns A deployed contract instance.
 */
export async function deployTokenWithMinter(wallet: Wallet, deployer: AztecAddress, options?: DeployOptions) {
  const contract = await TokenContract.deployWithOpts(
    { method: 'constructor_with_minter', wallet },
    'PrivateToken',
    'PT',
    18,
    deployer,
    AztecAddress.ZERO,
  ).send({ ...options, from: deployer });
  return contract;
}

/**
 * Deploys the Token contract with a specified initial supply.
 * @param wallet - The wallet to deploy the contract with.
 * @param deployer - The account to deploy the contract with.
 * @returns A deployed contract instance.
 */
export async function deployTokenWithInitialSupply(wallet: Wallet, deployer: AztecAddress, options?: DeployOptions) {
  const contract = await TokenContract.deployWithOpts(
    { method: 'constructor_with_initial_supply', wallet },
    'PrivateToken',
    'PT',
    18,
    0,
    deployer,
    deployer,
  ).send({ ...options, from: deployer });
  return contract;
}

// --- NFT Utils ---

// Check if an address owns a specific NFT in public state
export async function assertOwnsPublicNFT(
  nft: NFTContract,
  tokenId: bigint,
  expectedOwner: AztecAddress,
  expectToBeTrue: boolean,
  caller?: AztecAddress,
) {
  const from = caller ? (caller instanceof AztecAddress ? caller : caller) : expectedOwner;
  const owner = await nft.methods.public_owner_of(tokenId).simulate({ from });
  expect(owner.equals(expectedOwner)).toBe(expectToBeTrue);
}

// Check if an address owns a specific NFT in private state
export async function assertOwnsPrivateNFT(
  nft: NFTContract,
  tokenId: bigint,
  owner: AztecAddress,
  expectToBeTrue: boolean,
  caller?: AztecAddress,
) {
  const from = caller ? (caller instanceof AztecAddress ? caller : caller) : owner;
  const [nfts, _] = await nft.methods.get_private_nfts(owner, 0).simulate({ from });
  const hasNFT = nfts.some((id: bigint) => id === tokenId);
  expect(hasNFT).toBe(expectToBeTrue);
}

// Deploy NFT contract with a minter
export async function deployNFTWithMinter(wallet: EmbeddedWallet, deployer: AztecAddress, options?: DeployOptions) {
  const contract = await NFTContract.deployWithOpts(
    { method: 'constructor_with_minter', wallet },
    'TestNFT',
    'TNFT',
    deployer,
    deployer,
  ).send({ ...options, from: deployer });
  return contract;
}
