import { SupabaseService } from '../supabase/supabase.service';
import { CreateCohortApplicationDto } from './dto/create-cohort-application.dto';
export declare class ConnectedService {
    private readonly supabase;
    private get db();
    constructor(supabase: SupabaseService);
    create(dto: CreateCohortApplicationDto): Promise<{
        success: boolean;
        id: any;
    }>;
    findAll(status?: string): Promise<any[]>;
    updateStatus(id: string, status: string, reviewedBy?: string, reviewNotes?: string): Promise<any>;
}
