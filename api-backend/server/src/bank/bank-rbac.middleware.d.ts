import { NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { SupabaseService } from '../supabase/supabase.service';
export declare class BankRbacInterceptor implements NestInterceptor {
    private readonly supabase;
    constructor(supabase: SupabaseService);
    private get db();
    intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<any>>;
    private validatePermission;
    private logDataAccess;
    private checkConsent;
    private maskPII;
    private processPayload;
}
