import { SupabaseService } from '../supabase/supabase.service';
import { SalesforceService } from './salesforce.service';
export declare class BankCronService {
    private readonly supabase;
    private readonly salesforce;
    constructor(supabase: SupabaseService, salesforce: SalesforceService);
    private get db();
    checkSanctionExpiries(): Promise<void>;
    checkSanctionExpiryWarnings(): Promise<void>;
    checkSlaBreaches(): Promise<void>;
    autoSalesforceSync(): Promise<void>;
    checkQuerySlaTimers(): Promise<void>;
}
