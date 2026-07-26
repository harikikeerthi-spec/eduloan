import { SupabaseService } from '../supabase/supabase.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
export declare class SlackIntegrationService {
    private readonly supabase;
    private readonly eventEmitter;
    constructor(supabase: SupabaseService, eventEmitter: EventEmitter2);
    private get db();
    handleWebhookEvent(payload: any, signature: string): Promise<boolean>;
    configureIntegration(config: any, userId: string): Promise<any>;
    createAutoPostRule(ruleData: any): Promise<any>;
    getAutoPostRules(): Promise<any[]>;
    postToSlack(channelId: string, message: any, template?: string): Promise<{
        messageTs: string;
    }>;
    autoPostDecisionOrQuery(sourceType: string, sourceData: any): Promise<boolean>;
    testIntegration(): Promise<{
        success: boolean;
        teamInfo?: any;
        channels?: any[];
    }>;
    getMessageHistory(limit?: number): Promise<any[]>;
    private verifyWebhookSignature;
}
export declare class SalesforceIntegrationService {
    private readonly supabase;
    private readonly eventEmitter;
    constructor(supabase: SupabaseService, eventEmitter: EventEmitter2);
    private get db();
    authenticateSalesforce(authData: any): Promise<{
        success: boolean;
        message: string;
    }>;
    private getAccessToken;
    triggerSync(objectType?: string): Promise<{
        synced: number;
        failed: number;
        errors: Array<{
            id: string;
            reason: string;
        }>;
    }>;
    syncUserToSalesforce(userId: string, userData: any): Promise<string>;
    syncApplicationToSalesforce(applicationId: string, appData: any): Promise<string>;
    getSyncStatus(): Promise<any>;
    getSyncAuditLogs(limit?: number, objectType?: string): Promise<any[]>;
    testConnection(): Promise<{
        success: boolean;
        message: string;
    }>;
    retryFailedSyncs(): Promise<{
        retriedCount: number;
        successCount: number;
    }>;
    autoSyncApplicationStatusChange(applicationId: string, newStatus: string): Promise<void>;
    private mapApplicationToOpportunity;
}
