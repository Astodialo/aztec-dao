import { Wallet } from "@aztec/aztec.js/wallet";
import {
  GovernanceContract,
  GovernanceContractArtifact,
} from "../artifacts/Governance.js";
import { AztecAddress } from "@aztec/stdlib/aztec-address";
import { Contract } from "@aztec/aztec.js/contracts";
import { PublicKeys } from "@aztec/stdlib/keys";
import { Fr } from "@aztec/aztec.js/fields";
import { createStore } from '@aztec/kv-store/lmdb-v2';
import { type AztecLMDBStoreV2 } from '@aztec/kv-store/lmdb-v2';
import { createPXE, getPXEConfig, PXE } from "@aztec/pxe/server";
import { createAztecNodeClient } from "@aztec/aztec.js/node";
import { registerInitialSandboxAccountsInWallet, TestWallet } from "@aztec/test-wallet/server";

const { PXE_VERSION = '2' } = process.env;
const pxeVersion = parseInt(PXE_VERSION);

const { NODE_URL = 'http://localhost:8080' } = process.env;
const node = createAztecNodeClient(NODE_URL);

const l1Contracts = await node.getL1ContractAddresses();
const config = getPXEConfig();
const fullConfig = { ...config, l1Contracts };
fullConfig.proverEnabled = false;


export const setupPXE = async (suffix?: string) => {
  const storeDir = suffix ? `store-${suffix}` : 'store';
  const store: AztecLMDBStoreV2 = await createStore('pxe', pxeVersion, {
    dataDirectory: storeDir,
    dataStoreMapSizeKb: 1e6,
  });
  const pxe: PXE = await createPXE(node, fullConfig, { store });
  return { pxe, store };
};

/**
 * Setup the PXE, the store and the wallet
 * @param suffix - optional - The suffix to use for the store directory.
 * @returns The PXE, the store, the wallet and the accounts
 */
export const setupTestSuite = async (suffix?: string) => {
  const { pxe, store } = await setupPXE(suffix);
  const aztecNode = createAztecNodeClient(NODE_URL);
  const wallet: TestWallet = await TestWallet.create(aztecNode);
  const accounts: AztecAddress[] = await registerInitialSandboxAccountsInWallet(wallet);

  return {
    pxe,
    store,
    wallet,
    accounts,
  };
};

export async function deployGovernance(
  publicKeys: PublicKeys,
  wallet: Wallet,
  deployer: AztecAddress,
  salt: Fr = Fr.random(),
  args: unknown[] = [],
  constructor?: string,
): Promise<GovernanceContract> {
  const contract = await Contract.deployWithPublicKeys(publicKeys, wallet, GovernanceContractArtifact, args, constructor)
    .send({ contractAddressSalt: salt, universalDeploy: true, from: deployer })
    .deployed()
  return contract as GovernanceContract;
}
