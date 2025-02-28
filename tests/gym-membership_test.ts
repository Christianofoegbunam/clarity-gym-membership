[Previous test content]

Clarinet.test({
    name: "Test membership remaining time calculation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // Register membership
        let block = chain.mineBlock([
            Tx.contractCall('gym-membership', 'register-membership', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        // Check remaining time
        let timeBlock = chain.mineBlock([
            Tx.contractCall('gym-membership', 'get-remaining-time', [
                types.principal(wallet1.address)
            ], wallet1.address)
        ]);
        
        // Should be close to membership duration
        timeBlock.receipts[0].result.expectOk();
    }
});
