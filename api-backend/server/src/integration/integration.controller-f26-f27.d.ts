export declare class CreateSlackConfigDto {
    teamId: string;
    teamName?: string;
    botToken: string;
    webhookUrl?: string;
    webhookSecret?: string;
    channelMappings?: Record<string, string>;
}
export declare class CreateSlackRuleDto {
    eventType: string;
    channelId: string;
    condition?: Record<string, any>;
    template?: string;
    isEnabled?: boolean;
}
export declare class SlackIntegrationController {
    handleSlackWebhook(payload: any, req: any): Promise<{
        ok: boolean;
    }>;
    configureSlack(dto: CreateSlackConfigDto, req: any): Promise<any>;
    createAutoPostRule(dto: CreateSlackRuleDto, req: any): Promise<any>;
    getAutoPostRules(): Promise<any[]>;
    updateAutoPostRule(dto: Partial<CreateSlackRuleDto>, req: any): Promise<any>;
    testSlackIntegration(req: any): Promise<{
        success: boolean;
        message: string;
    }>;
    getSlackMessageHistory(limit?: number): Promise<any[]>;
}
export declare class SalesforceAuthDto {
    instanceUrl: string;
    clientId: string;
    clientSecret: string;
    username?: string;
    password?: string;
    securityToken?: string;
}
export declare class SalesforceConfigDto {
    fieldMapping?: Record<string, string>;
    autoSync?: boolean;
    syncInterval?: number;
}
export declare class SalesforceIntegrationController {
    authenticateSalesforce(dto: SalesforceAuthDto, req: any): Promise<{
        success: boolean;
        message: string;
    }>;
    configureSalesforce(dto: SalesforceConfigDto, req: any): Promise<any>;
    triggerSalesforceSync(req: any, objectType?: 'Contact' | 'Lead' | 'Opportunity'): Promise<{
        synced: number;
        failed: number;
        errors: Array<{
            id: string;
            reason: string;
        }>;
    }>;
    getSyncStatus(): Promise<{
        lastSync: Date;
        nextScheduledSync: Date;
        pendingRecords: number;
        failedRecords: number;
    }>;
    getSyncAuditLogs(limit?: number, objectType?: string): Promise<any[]>;
    testSalesforceConnection(): Promise<{
        success: boolean;
        message: string;
    }>;
}
