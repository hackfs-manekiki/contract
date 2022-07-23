import { ethers } from 'ethers'
import * as VaultArtifact from '../../out/Vault.sol/Vault.json'
import * as TokenArtifact from '../../out/MockToken.sol/MockToken.json'

async function main() {
    const privateKey = '0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6'
    const vaultAddress = '0xa16e02e87b7454126e5e10d957a927a7f5b5d2be'

    const provider = ethers.providers.getDefaultProvider('http://localhost:8545')
    const wallet = new ethers.Wallet(privateKey, provider)
    // mock token
    const tokenFactory = new ethers.ContractFactory(TokenArtifact.abi, TokenArtifact.bytecode.object, wallet)
    const token = await tokenFactory.deploy('USD', 'USD', 6)
    console.log(`token: ${token.address}`)
    await token.mint(vaultAddress, 100000_000000)
    // vault
    const vault = new ethers.Contract(vaultAddress, VaultArtifact.abi, wallet)
    let tokenInterface = new ethers.utils.Interface(TokenArtifact.abi)
    let data = tokenInterface.encodeFunctionData('transfer', [wallet.address, '1000000000'])
    const requestToken = {
        requester: wallet.address,
        to: token.address,
        requestType: '1', // EXECUTE
        value: '0',
        budget: '1000000000',
        data,
        name: 'test transfer token',
        detail: 'hello world',
        attachments: 'ipfs://'
    }
    await vault.requestApproval(requestToken)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });