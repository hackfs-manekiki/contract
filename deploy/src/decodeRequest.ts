import { ethers } from 'ethers'
import * as VaultArtifact from '../../out/Vault.sol/Vault.json'

async function main() {
    const input = '0x7ea42aaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0ee7a142d267c1f36714e4a8f75612f20a797200000000000000000000000000000000000000000000000000de0b6b3a7640000000000000000000000000000000000000000000000000000000000003b9aca0000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000'
    let vaultInterface = new ethers.utils.Interface(VaultArtifact.abi)
    let result = vaultInterface.decodeFunctionData('requestApproval', input)
    console.log(result)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });