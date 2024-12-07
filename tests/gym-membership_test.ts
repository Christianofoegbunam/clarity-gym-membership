import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test membership registration",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('gym-membership', 'register-membership', [], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Check membership status
        let statusBlock = chain.mineBlock([
            Tx.contractCall('gym-membership', 'get-membership-status', [
                types.principal(wallet1.address)
            ], wallet1.address)
        ]);
        
        assertEquals(statusBlock.receipts[0].result.expectOk(), true);
    }
});

Clarinet.test({
    name: "Test membership renewal",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        // First register
        let block = chain.mineBlock([
            Tx.contractCall('gym-membership', 'register-membership', [], wallet1.address)
        ]);
        
        // Then renew
        let renewBlock = chain.mineBlock([
            Tx.contractCall('gym-membership', 'renew-membership', [], wallet1.address)
        ]);
        
        renewBlock.receipts[0].result.expectOk();
    }
});

Clarinet.test({
    name: "Test membership cancellation by owner",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        // First register
        let block = chain.mineBlock([
            Tx.contractCall('gym-membership', 'register-membership', [], wallet1.address)
        ]);
        
        // Then cancel
        let cancelBlock = chain.mineBlock([
            Tx.contractCall('gym-membership', 'cancel-membership', [
                types.principal(wallet1.address)
            ], deployer.address)
        ]);
        
        cancelBlock.receipts[0].result.expectOk();
        
        // Verify status
        let statusBlock = chain.mineBlock([
            Tx.contractCall('gym-membership', 'get-membership-status', [
                types.principal(wallet1.address)
            ], wallet1.address)
        ]);
        
        assertEquals(statusBlock.receipts[0].result.expectOk(), false);
    }
});
