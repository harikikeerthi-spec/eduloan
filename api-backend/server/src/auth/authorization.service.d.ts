import { SupabaseService } from '../supabase/supabase.service';
export type AppUser = {
    id: string;
    email: string;
    firstName: string | null;
    lastName: string | null;
    role: string;
    [key: string]: any;
};
export declare class AuthorizationService {
    private supabase;
    private get db();
    constructor(supabase: SupabaseService);
    canEditBlog(blogId: string, user: AppUser): Promise<boolean>;
    canViewBlog(blogId: string, user: AppUser): Promise<boolean>;
    canDeleteBlog(blogId: string, user: AppUser): Promise<boolean>;
    getVisibilityFilter(user: AppUser, scope?: 'own' | 'other' | 'all'): {
        role: string;
        userId: string;
        scope: "own" | "other" | "all" | undefined;
    };
    getPublicFilter(): {
        isPublished: boolean;
        visibility: string;
    };
}
