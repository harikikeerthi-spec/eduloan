import { CanActivate, ExecutionContext } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { SupabaseService } from '../supabase/supabase.service';
export declare class MentorGuard implements CanActivate {
    private jwtService;
    private supabase;
    constructor(jwtService: JwtService, supabase: SupabaseService);
    canActivate(context: ExecutionContext): Promise<boolean>;
    private extractTokenFromHeader;
}
