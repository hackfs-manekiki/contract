import { ethers } from 'ethers'
import * as VaultArtifact from '../../out/Vault.sol/Vault.json'

async function main() {
    const privateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'

    const provider = ethers.providers.getDefaultProvider('http://localhost:8545')
    const wallet = new ethers.Wallet(privateKey, provider)
    const factory = new ethers.ContractFactory(VaultArtifact.abi, VaultArtifact.bytecode.object, wallet)
    const vault = await factory.deploy(
        wallet.address,
        ['0x70997970c51812dc3a010c7d01b50e0d17dc79c8', '0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc'],
        [
            {
                approver: '0x90f79bf6eb2c4f870365e785982e1f101e93b906',
                budget: '1000000000'
            }
        ])
    console.log(vault.address)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });