import {
  GovernanceContract,
  GovernanceContractArtifact,
} from "../artifacts/Governance.js";
import { describe, it, expect, beforeAll, beforeEach, afterEach } from "vitest";
import { TestWallet } from "@aztec/test-wallet/server";
import { createAztecNodeClient } from "@aztec/aztec.js/node";
import { deployGovernance, setupTestSuite } from "./utils.js";
import { AztecAddress } from "@aztec/stdlib/aztec-address";
import { type AztecLMDBStoreV2 } from "@aztec/kv-store/lmdb-v2";

import {
  INITIAL_TEST_SECRET_KEYS,
  INITIAL_TEST_ACCOUNT_SALTS,
  INITIAL_TEST_ENCRYPTION_KEYS,
} from "@aztec/accounts/testing";
import { ContractDeployer } from "@aztec/aztec.js/deployment";
import { PXE } from "@aztec/pxe/server";
import { Fr, GrumpkinScalar } from "@aztec/aztec.js/fields";
import { deriveKeys, PublicKeys } from "@aztec/stdlib/keys";
import { getContractInstanceFromInstantiationParams } from "@aztec/stdlib/contract";

describe("Counter Contract", () => {
  let pxe: PXE;
  let store: AztecLMDBStoreV2;

  let wallet: TestWallet;
  let accounts: AztecAddress[];

  let alice: AztecAddress;
  let bob: AztecAddress;

  let gov: GovernanceContract;
  let govSk: Fr;
  let govKeys: {
    masterNullifierSecretKey: GrumpkinScalar;
    masterIncomingViewingSecretKey: GrumpkinScalar;
    masterOutgoingViewingSecretKey: GrumpkinScalar;
    masterTaggingSecretKey: GrumpkinScalar;
    publicKeys: PublicKeys;
  };
  let govSalt: Fr;

  beforeEach(async () => {
    ({ pxe, store, wallet, accounts } = await setupTestSuite());

    [alice, bob] = accounts;

    govSk = Fr.random();
    govKeys = await deriveKeys(govSk);
    govSalt = Fr.random();

    // Precompute contract address and register keys
    //const contractInstance = await getContractInstanceFromInstantiationParams(
    //  GovernanceContractArtifact,
    //  {
    //    constructorArgs: [alice],
    //    salt: govSalt,
    //    deployer: alice,
    //  }
    //);

    gov = (await deployGovernance(
      govKeys.publicKeys,
      wallet,
      alice,
      govSalt,
      [alice],
      "constructor",
    )) as GovernanceContract;

    await wallet.registerContract(
      gov.instance, //contractInstance,
      GovernanceContractArtifact,
      govSk,
    );

    console.log("Contract address: ", gov.address);
    console.log("Contract Keys: ", govKeys);

    // Register initial test accounts manually because of this:
    // https://github.com/AztecProtocol/aztec-packages/blame/next/yarn-project/accounts/src/schnorr/lazy.ts#L21-L25
    [alice] = await Promise.all(
      INITIAL_TEST_SECRET_KEYS.map(async (secret, i) => {
        const accountManager = await wallet.createSchnorrAccount(
          secret,
          INITIAL_TEST_ACCOUNT_SALTS[i],
          INITIAL_TEST_ENCRYPTION_KEYS[i],
        );
        return accountManager.address;
      }),
    );
  });

  afterEach(async () => {
    await store.delete();
  });

  it("Deploys", async () => {
    const current_id = await gov.methods._view_current_id().simulate({
      from: alice,
    });

    console.log(current_id);

    //starting counter's value is 0
    expect(current_id).toStrictEqual(0n);
  });
});
