import { ethers } from 'ethers'
import * as VaultArtifact from '../../out/Vault.sol/Vault.json'

async function main() {
    const privateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'
    const vaultAddress = '0xa16e02e87b7454126e5e10d957a927a7f5b5d2be'

    const provider = ethers.providers.getDefaultProvider('http://localhost:8545')
    const wallet = new ethers.Wallet(privateKey, provider)
    const vault = new ethers.Contract(vaultAddress, VaultArtifact.abi, wallet)
    await vault.approveRequest(1)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });