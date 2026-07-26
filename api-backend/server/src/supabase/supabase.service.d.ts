import { SupabaseClient } from '@supabase/supabase-js';
export declare class SupabaseService {
    readonly client: SupabaseClient;
    constructor();
    getClient(): SupabaseClient;
    from(table: string): import("@supabase/postgrest-js").PostgrestQueryBuilder<any, any, any, string, unknown>;
}
