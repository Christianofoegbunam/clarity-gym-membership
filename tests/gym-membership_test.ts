Clarinet.test({
    name: "Test complete membership lifecycle",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const deployer = accounts.get('deployer')!;
        
        // Test registration
        let block = chain.mineBlock([
            Tx.contractCall('gym-membership', 'register-membership', [
                types.uint(1)
            ], wallet1.address)
        ]);
        block.receipts[0].result.expectOk();
        
        // Test tier check
        let tierBlock = chain.mineBlock([
            Tx.contractCall('gym-membership', 'get-membership-tier', [
                types.principal(wallet1.address)
            ], wallet1.address)
        ]);
        tierBlock.receipts[0].result.expectOk().expectUint(1);
        
        // Test cancellation
        let cancelBlock = chain.mineBlock([
            Tx.contractCall('gym-membership', 'cancel-membership', [
                types.principal(wallet1.address)
            ], deployer.address)
        ]);
        cancelBlock.receipts[0].result.expectOk();
    }
});

[Previous tests remain unchanged...]
