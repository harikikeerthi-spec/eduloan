import { SupabaseService } from '../supabase/supabase.service';
export declare class BlogService {
    private supabase;
    private get db();
    constructor(supabase: SupabaseService);
    private normalizeTagName;
    private slugifyTag;
    private upsertTags;
    private mapTags;
    getAllBlogs(options?: {
        category?: string;
        featured?: boolean;
        limit?: number;
        offset?: number;
    }): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: number;
            offset: number;
            hasMore: boolean;
        };
    }>;
    getFeaturedBlog(): Promise<{
        success: boolean;
        message: string;
        data: null;
    } | {
        success: boolean;
        data: any;
        message?: undefined;
    }>;
    getBlogBySlug(slug: string): Promise<{
        success: boolean;
        data: any;
    }>;
    getBlogById(id: string): Promise<{
        success: boolean;
        data: any;
    }>;
    getPopularBlogs(limit?: number): Promise<{
        success: boolean;
        data: any[];
    }>;
    getBlogStats(id: string): Promise<{
        success: boolean;
        data: {
            daysSincePublished: number | null;
            id: any;
            title: any;
            slug: any;
            views: any;
            category: any;
            publishedAt: any;
            createdAt: any;
            updatedAt: any;
            isFeatured: any;
            isPublished: any;
        };
    }>;
    incrementBlogView(id: string): Promise<{
        success: boolean;
        views: any;
    }>;
    getCategories(): Promise<{
        success: boolean;
        data: {
            name: string;
            count: number;
        }[];
    }>;
    getRelatedBlogs(category: string, excludeSlug: string, limit?: number): Promise<{
        success: boolean;
        data: any[];
    }>;
    createBlog(data: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    updateBlog(id: string, data: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    deleteBlog(id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    searchBlogs(query: string, limit?: number): Promise<{
        success: boolean;
        data: any[];
        count: number;
    }>;
    getAllTags(limit?: number): Promise<{
        success: boolean;
        data: {
            name: any;
            slug: any;
            count: any;
        }[];
    }>;
    searchBlogsByTag(tag: string, limit?: number, offset?: number): Promise<{
        success: boolean;
        data: any[];
        count: number;
        pagination: {
            total: number;
            limit: number;
            offset: number;
            hasMore: boolean;
        };
    }>;
    addCommentToBlog(blogId: string, data: {
        author: string;
        content: string;
    }): Promise<{
        success: boolean;
        message: string;
        data: {
            id: any;
            author: any;
            content: any;
            createdAt: any;
        };
    }>;
    addReplyToComment(commentId: string, data: {
        author: string;
        content: string;
    }): Promise<{
        success: boolean;
        message: string;
        data: {
            id: any;
            author: any;
            content: any;
            likes: any;
            createdAt: any;
        };
    }>;
    deleteComment(commentId: string): Promise<{
        success: boolean;
        message: string;
    }>;
    toggleCommentLike(commentId: string, userId: string): Promise<{
        success: boolean;
        message: string;
        liked: boolean;
        likesCount: any;
    }>;
    getCommentsForBlog(blogId: string, limit?: number, offset?: number): Promise<{
        success: boolean;
        data: {
            id: any;
            author: any;
            content: any;
            likes: any;
            createdAt: any;
            replies: {
                id: any;
                author: any;
                content: any;
                likes: any;
                createdAt: any;
            }[];
        }[];
        pagination: {
            total: number;
            limit: number;
            offset: number;
            hasMore: boolean;
        };
    }>;
    getAllBlogsAdmin(options?: {
        limit?: number;
        offset?: number;
        status?: string;
        timeRange?: string;
    }): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: number;
            offset: number;
            hasMore: boolean;
        };
    }>;
    getBlogStatistics(): Promise<{
        success: boolean;
        data: {
            total: number;
            published: number;
            draft: number;
            featured: number;
            totalViews: any;
        };
    }>;
    bulkDeleteBlogs(blogIds: string[]): Promise<{
        success: boolean;
        message: string;
        deleted?: undefined;
    } | {
        success: boolean;
        message: string;
        deleted: number;
    }>;
    bulkUpdateStatus(blogIds: string[], isPublished: boolean): Promise<{
        success: boolean;
        message: string;
        updated?: undefined;
    } | {
        success: boolean;
        message: string;
        updated: number;
    }>;
    submitForApproval(blogId: string, notes?: string): Promise<any>;
    publishBlog(blogId: string, visibility?: 'private' | 'public'): Promise<any>;
    unpublishBlog(blogId: string, reason?: string): Promise<any>;
    approveBlog(blogId: string, approvedBy: string, notes?: string): Promise<any>;
    rejectBlog(blogId: string, reason: string): Promise<any>;
    getAdminBlogs(filter: any, options?: {
        limit?: number;
        offset?: number;
    }): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: number;
            offset: number;
            hasMore: boolean;
        };
    }>;
    getAdminBlogDetail(blogId: string): Promise<any>;
}
