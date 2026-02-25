import { createLogger } from "@aztec/aztec.js/log";
import { AztecAddress } from "@aztec/aztec.js/addresses";
import { type Wallet } from "@aztec/aztec.js/wallet";
import { Fr } from "@aztec/aztec.js/fields";
import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";
import { registerInitialLocalNetworkAccountsInWallet } from "@aztec/wallets/testing";
import { EmbeddedWallet } from "@aztec/wallets/embedded";
import { PublicKeys } from "@aztec/stdlib/keys";
import { Contract } from "@aztec/aztec.js/contracts";

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

export const logger = createLogger("aztec:aztec-dao");

const { NODE_URL = "http://localhost:8080" } = process.env;

/**
 * Setup the node, wallet and accounts for testing against a running Aztec network
 * @param proverEnabled - optional - Whether to enable the prover, used for benchmarking.
 * @returns The node, wallet and accounts
 */
export const setupTestSuite = async (proverEnabled: boolean = false) => {
  const node = createAztecNodeClient(NODE_URL);
  await waitForNode(node, logger);

  const wallet: EmbeddedWallet = await EmbeddedWallet.create(node);
  const accounts: AztecAddress[] =
    await registerInitialLocalNetworkAccountsInWallet(wallet);

  return {
    node,
    wallet,
    accounts,
  };
};

export async function deployTreasury(
  publicKeys: PublicKeys,
  wallet: Wallet,
  deployer: AztecAddress,
  salt: Fr = Fr.random(),
  args: unknown[] = [],
  constructor?: string,
  secretKey?: Fr,
): Promise<TreasuryContract> {
  const deployment = Contract.deployWithPublicKeys(
    publicKeys,
    wallet,
    TreasuryContractArtifact,
    args,
    constructor,
  );

  // Register contract BEFORE sending if secretKey provided
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
  args: unknown[] = [],
  constructor?: string,
  secretKey?: Fr,
): Promise<MembersContract> {
  const deployment = Contract.deployWithPublicKeys(
    publicKeys,
    wallet,
    MembersContractArtifact,
    args,
    constructor,
  );

  // Register contract BEFORE sending if secretKey provided
  if (secretKey) {
    const instance = await deployment.getInstance();
    await wallet.registerContract(instance, MembersContractArtifact, secretKey);
  }

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
  args: unknown[] = [],
  constructor?: string,
  secretKey?: Fr,
): Promise<GovernanceContract> {
  const deployment = Contract.deployWithPublicKeys(
    publicKeys,
    wallet,
    GovernanceContractArtifact,
    args,
    constructor,
  );

  // Register contract BEFORE sending if secretKey provided
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

export const expectTokenBalances = async (
  token: TokenContract,
  address: AztecAddress,
  publicBalance: bigint | number | Fr,
  privateBalance: bigint | number | Fr,
  caller?: AztecAddress,
) => {
  const aztecAddress =
    address instanceof AztecAddress ? address : new AztecAddress(address);
  logger.info(`checking balances for ${aztecAddress.toString()}`);
  // We can't use an account that is not in the wallet to simulate the balances, so we use the caller if provided.
  const from = caller ? caller : aztecAddress;

  // Helper to cast to bigint if not already
  const toBigInt = (val: bigint | number | Fr) => {
    if (typeof val === "bigint") return val;
    if (typeof val === "number") return BigInt(val);
    if (val instanceof Fr) return val.toBigInt();
    throw new Error("Unsupported type for balance");
  };

  expect(
    await token.methods.balance_of_public(aztecAddress).simulate({ from }),
  ).toBe(toBigInt(publicBalance));
  expect(
    await token.methods.balance_of_private(aztecAddress).simulate({ from }),
  ).toBe(toBigInt(privateBalance));
};

export const AMOUNT = 1000n;
export const wad = (n: number = 1) => AMOUNT * BigInt(n);

/**
 * Deploys the Token contract with a specified minter.
 * @param wallet - The wallet to deploy the contract with.
 * @param deployer - The account to deploy the contract with.
 * @returns A deployed contract instance.
 */
export async function deployTokenWithMinter(
  wallet: Wallet,
  deployer: AztecAddress,
) {
  const { contract } = await Contract.deploy(
    wallet,
    TokenContractArtifact,
    ["PrivateToken", "PT", 18, deployer, AztecAddress.ZERO],
    "constructor_with_minter",
  ).send({
    from: deployer,
    wait: { returnReceipt: true },
  });
  return contract;
}

/**
 * Deploys the Token contract with a specified initial supply.
 * @param wallet - The wallet to deploy the contract with.
 * @param deployer - The account to deploy the contract with.
 * @returns A deployed contract instance.
 */
export async function deployTokenWithInitialSupply(
  wallet: Wallet,
  deployer: AztecAddress,
) {
  const { contract } = await Contract.deploy(
    wallet,
    TokenContractArtifact,
    ["PrivateToken", "PT", 18, 0, deployer, deployer],
    "constructor_with_initial_supply",
  ).send({
    from: deployer,
    wait: { returnReceipt: true },
  });
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
  const from = caller
    ? caller instanceof AztecAddress
      ? caller
      : caller
    : expectedOwner;
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
  const from = caller
    ? caller instanceof AztecAddress
      ? caller
      : caller
    : owner;
  const [nfts, _] = await nft.methods
    .get_private_nfts(owner, 0)
    .simulate({ from });
  const hasNFT = nfts.some((id: bigint) => id === tokenId);
  expect(hasNFT).toBe(expectToBeTrue);
}

// Deploy NFT contract with a minter
export async function deployNFTWithMinter(
  wallet: EmbeddedWallet,
  deployer: AztecAddress,
) {
  const { contract } = await Contract.deploy(
    wallet,
    NFTContractArtifact,
    ["TestNFT", "TNFT", deployer, deployer],
    "constructor_with_minter",
  ).send({
    from: deployer,
    wait: { returnReceipt: true },
  });
  return contract;
}
