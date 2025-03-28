import { initialize } from 'zokrates-js';
import chalk from "chalk"
import fs from "fs"
import path from "path"
import fse from 'fs-extra'

export async function proof_compare(bit1,bit2,bit3,hash_bit1,hash_bit2,hash_bit3) {
initialize().then(async (zokratesProvider) => {

    let rawdata = fs.readFileSync('./zokrates/compare.zok');

    const source = rawdata.toString();

    const artifacts = zokratesProvider.compile(source);

    const { witness, output } = zokratesProvider.computeWitness(artifacts, [bit1,bit2,bit3,hash_bit1,hash_bit2,hash_bit3]);

    const keypair = zokratesProvider.setup(artifacts.program);

    const proof = zokratesProvider.generateProof(artifacts.program, witness, keypair.pk);
    fse.outputFile("./proofs/proof_compare.json", JSON.stringify(proof));
    console.log(chalk.green("\nProofs generated successfully"));

    const verifier = zokratesProvider.exportSolidityVerifier(keypair.vk, "v1");
    fse.outputFile("./contracts/verifier_compare.sol", verifier);
    console.log(chalk.green("\nContracts generated successfully"));

});}
proof_compare("5", "6", "7", ["263561599766550617289250058199814760685", "65303172752238645975888084098459749904"], ["296016139321527823785053958024045515449", "169585634993304848991863197817116667302"], ["62133134181886812829768166950054220896", "160635334427203623512968684759912538624"])