import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test basic tier membership registration",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('gym-membership', 'register-membership', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Check membership details
        let detailsBlock = chain.mineBlock([
            Tx.contractCall('gym-membership', 'get-membership-details', [
                types.principal(wallet1.address)
            ], wallet1.address)
        ]);
        
        let details = detailsBlock.receipts[0].result.expectOk();
        assertEquals(details.tier, types.uint(1));
    }
});

Clarinet.test({
    name: "Test membership tier upgrade",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        // Register basic membership
        let block = chain.mineBlock([
            Tx.contractCall('gym-membership', 'register-membership', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        // Upgrade to premium
        let upgradeBlock = chain.mineBlock([
            Tx.contractCall('gym-membership', 'upgrade-tier', [
                types.uint(2)
            ], wallet1.address)
        ]);
        
        upgradeBlock.receipts[0].result.expectOk();
        
        // Verify new tier
        let detailsBlock = chain.mineBlock([
            Tx.contractCall('gym-membership', 'get-membership-details', [
                types.principal(wallet1.address)
            ], wallet1.address)
        ]);
        
        let details = detailsBlock.receipts[0].result.expectOk();
        assertEquals(details.tier, types.uint(2));
    }
});

Clarinet.test({
    name: "Test membership renewal with existing tier",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        // Register premium membership
        let block = chain.mineBlock([
            Tx.contractCall('gym-membership', 'register-membership', [
                types.uint(2)
            ], wallet1.address)
        ]);
        
        // Renew membership
        let renewBlock = chain.mineBlock([
            Tx.contractCall('gym-membership', 'renew-membership', [], wallet1.address)
        ]);
        
        renewBlock.receipts[0].result.expectOk();
        
        // Verify tier remained same
        let detailsBlock = chain.mineBlock([
            Tx.contractCall('gym-membership', 'get-membership-details', [
                types.principal(wallet1.address)
            ], wallet1.address)
        ]);
        
        let details = detailsBlock.receipts[0].result.expectOk();
        assertEquals(details.tier, types.uint(2));
    }
});
