import { Note } from '@aztec/aztec.js/note';
import { createLogger } from '@aztec/aztec.js/log';
import { AztecAddress } from '@aztec/aztec.js/addresses';
import { Aes128 } from '@aztec/foundation/crypto/aes128';
import { deriveEcdhSharedSecret } from '@aztec/stdlib/logs';
import { type Wallet, AccountManager } from '@aztec/aztec.js/wallet';
import { Fr, type GrumpkinScalar, Point } from '@aztec/aztec.js/fields';
import { createAztecNodeClient, waitForNode } from '@aztec/aztec.js/node';
import { type ContractInstanceWithAddress } from '@aztec/aztec.js/contracts';
import { PRIVATE_LOG_CIPHERTEXT_LEN, GeneratorIndex } from '@aztec/constants';
import { poseidon2HashWithSeparator } from '@aztec/foundation/crypto/poseidon';
import { registerInitialLocalNetworkAccountsInWallet, TestWallet } from '@aztec/test-wallet/server';
import { deriveMasterIncomingViewingSecretKey, PublicKeys, computeAddressSecret } from '@aztec/stdlib/keys';

import {
  Contract,
  DeployOptions,
  ContractFunctionInteraction,
  getContractClassFromArtifact,
} from '@aztec/aztec.js/contracts';
import { AuthWitness, type ContractFunctionInteractionCallIntent } from '@aztec/aztec.js/authorization';
import { getDefaultInitializer } from '@aztec/stdlib/abi';
import {
  CompleteAddress,
  computeInitializationHash,
  computeSaltedInitializationHash,
  computeContractAddressFromInstance,
} from '@aztec/stdlib/contract';


import { createStore } from '@aztec/kv-store/lmdb-v2';
import { getPXEConfig } from '@aztec/pxe/server';
import { type AztecLMDBStoreV2 } from '@aztec/kv-store/lmdb-v2';
import { TreasuryContract, TreasuryContractArtifact } from '../artifacts/Treasury.js';
import { MembersContract, MembersContractArtifact } from '../artifacts/Members.js';
import { GovernanceContract, GovernanceContractArtifact } from '../artifacts/Governance.js';
import { expect } from 'vitest';
import { TokenContract, TokenContractArtifact } from '../artifacts/Token.js';
import { NFTContract, NFTContractArtifact } from '../artifacts/NFT.js';

export const logger = createLogger('aztec:aztec-standards');

const { NODE_URL = 'http://localhost:8080' } = process.env;
const node = createAztecNodeClient(NODE_URL);
await waitForNode(node);
const { PXE_VERSION = '2' } = process.env;
const pxeVersion = parseInt(PXE_VERSION);
const l1Contracts = await node.getL1ContractAddresses();
const config = getPXEConfig();
let fullConfig = { ...config, l1Contracts };

/**
 * Setup the store, node, wallet and accounts
 * @param suffix - optional - The suffix to use for the store directory.
 * @param proverEnabled - optional - Whether to enable the prover, used for benchmarking.
 * @returns The store, node, wallet and accounts
 */
export const setupTestSuite = async (suffix?: string, proverEnabled: boolean = false) => {
  const storeDir = suffix ? `store-${suffix}` : 'store';

  fullConfig = { ...fullConfig, dataDirectory: storeDir, dataStoreMapSizeKb: 1e6 };

  // Create the store for manual cleanups
  const store: AztecLMDBStoreV2 = await createStore('pxe_data', pxeVersion, {
    dataDirectory: storeDir,
    dataStoreMapSizeKb: 1e6,
  });

  const wallet: TestWallet = await TestWallet.create(node, { ...fullConfig, proverEnabled }, { store });


  const accounts: AztecAddress[] = await registerInitialLocalNetworkAccountsInWallet(wallet);

  return {
    store,
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
): Promise<TreasuryContract> {
  const contract = await Contract.deployWithPublicKeys(
    publicKeys,
    wallet,
    TreasuryContractArtifact,
    args,
    constructor,
  )
    .send({ contractAddressSalt: salt, universalDeploy: true, from: deployer })
    .deployed();
  return contract as TreasuryContract;
}

export async function deployMembers(
  publicKeys: PublicKeys,
  wallet: Wallet,
  deployer: AztecAddress,
  salt: Fr = Fr.random(),
  args: unknown[] = [],
  constructor?: string,
): Promise<MembersContract> {
  const contract = await Contract.deployWithPublicKeys(
    publicKeys,
    wallet,
    MembersContractArtifact,
    args,
    constructor,
  )
    .send({ contractAddressSalt: salt, universalDeploy: true, from: deployer })
    .deployed();
  return contract as MembersContract;
}

export async function deployGovernance(
  publicKeys: PublicKeys,
  wallet: Wallet,
  deployer: AztecAddress,
  salt: Fr = Fr.random(),
  args: unknown[] = [],
  constructor?: string,
): Promise<GovernanceContract> {
  const contractTx = Contract.deployWithPublicKeys(
    publicKeys,
    wallet,
    GovernanceContractArtifact,
    args,
    constructor,
  )

  //console.log("Deploy tx created", contractTx);
  const contractSend = contractTx
    .send({ contractAddressSalt: salt, universalDeploy: true, from: deployer });

  console.log("Sent tx:", contractSend);

  //console.log("DEPLOYER:", deployer);

  try {
    const contract = await contractSend.deployed();
    console.log("Deployed contract:", contract);
    return contract as GovernanceContract;
  } catch (err) {
    console.error("Error during contract deployment:", err);
    throw err;
  }

}

// --- Token Utils ---
export const expectUintNote = (note: Note, amount: bigint, owner: AztecAddress) => {
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
  options?: DeployOptions,
) {
  const contract = await Contract.deploy(
    wallet,
    TokenContractArtifact,
    ["PrivateToken", "PT", 18, deployer, AztecAddress.ZERO],
    "constructor_with_minter",
  )
    .send({ ...options, from: deployer })
    .deployed();
  return contract;
}
/**
 * Deploys the Token contract with a specified initial supply.
 * @param wallet - The wallet to deploy the contract with.
 * @param deployer - The account to deploy the contract with.
 * @returns A deployed contract instance.
 */
export async function deployTokenWithInitialSupply(wallet: Wallet, deployer: AztecAddress, options?: DeployOptions) {
  const contract = await Contract.deploy(
    wallet,
    TokenContractArtifact,
    ['PrivateToken', 'PT', 18, 0, deployer, deployer],
    'constructor_with_initial_supply',
  )
    .send({ ...options, from: deployer })
    .deployed();
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
export async function deployNFTWithMinter(wallet: TestWallet, deployer: AztecAddress, options?: DeployOptions) {
  const contract = await Contract.deploy(
    wallet,
    NFTContractArtifact,
    ['TestNFT', 'TNFT', deployer, deployer],
    'constructor_with_minter',
  )
    .send({
      ...options,
      from: deployer,
    })
    .deployed();
  return contract;
}
