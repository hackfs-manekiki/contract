import { ethers } from 'ethers'
import * as VaultArtifact from '../../out/Vault.sol/Vault.json'

async function main() {
    const privateKey = '0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6'
    const vaultAddress = '0xa16e02e87b7454126e5e10d957a927a7f5b5d2be'

    const provider = ethers.providers.getDefaultProvider('http://localhost:8545')
    const wallet = new ethers.Wallet(privateKey, provider)
    const vault = new ethers.Contract(vaultAddress, VaultArtifact.abi, wallet)
    await vault.requestApproval('0', wallet.address, ethers.utils.parseEther('1').toString(), '1000000000', '0x')
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });