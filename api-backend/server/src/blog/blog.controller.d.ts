import { BlogService } from './blog.service';
import { AuthorizationService } from '../auth/authorization.service';
import { AuditLogService } from '../auth/audit-log.service';
export declare class BlogController {
    private blogService;
    private authService;
    private auditLog;
    constructor(blogService: BlogService, authService: AuthorizationService, auditLog: AuditLogService);
    getAllAuditLogs(entityType?: string, initiatedBy?: string, limit?: string, offset?: string): Promise<{
        success: boolean;
        data: {
            id: any;
            action: any;
            entityType: any;
            entityId: any;
            createdAt: any;
            initiator: {
                firstName: any;
                lastName: any;
                email: any;
            }[];
        }[];
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
    getAllBlogs(category?: string, featured?: string, limit?: string, offset?: string): Promise<{
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
    getCategories(): Promise<{
        success: boolean;
        data: {
            name: string;
            count: number;
        }[];
    }>;
    searchBlogs(query: string, limit?: string): Promise<{
        success: boolean;
        data: any[];
        count: number;
    }>;
    getAllTags(limit?: string): Promise<{
        success: boolean;
        data: {
            name: any;
            slug: any;
            count: any;
        }[];
    }>;
    searchBlogsByTag(tag: string, limit?: string, offset?: string): Promise<{
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
    getRelatedBlogs(category: string, excludeSlug?: string, limit?: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    getBlogBySlug(slug: string): Promise<{
        success: boolean;
        data: any;
    }>;
    getPopularBlogs(limit?: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    getCommentsForBlog(id: string, limit?: string, offset?: string): Promise<{
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
    addCommentToBlog(id: string, body: {
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
    addReplyToComment(commentId: string, body: {
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
    toggleCommentLike(commentId: string, body: {
        userId: string;
    }): Promise<{
        success: boolean;
        message: string;
        liked: boolean;
        likesCount: any;
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
    getAllBlogsAdmin(limit?: string, offset?: string, status?: string, timeRange?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: number;
            offset: number;
            hasMore: boolean;
        };
    }>;
    createBlog(body: {
        title: string;
        slug: string;
        excerpt: string;
        content: string;
        category: string;
        authorName: string;
        authorImage?: string;
        authorRole?: string;
        featuredImage?: string;
        readTime?: number;
        isFeatured?: boolean;
        isPublished?: boolean;
        authorId?: string;
        tags?: string[];
    }, req: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    incrementBlogView(id: string): Promise<{
        success: boolean;
        views: any;
    }>;
    getBlogById(id: string): Promise<{
        success: boolean;
        data: any;
    }>;
    deleteBlog(id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    updateBlog(id: string, body: {
        title?: string;
        slug?: string;
        excerpt?: string;
        content?: string;
        category?: string;
        authorName?: string;
        authorImage?: string;
        authorRole?: string;
        featuredImage?: string;
        readTime?: number;
        isFeatured?: boolean;
        isPublished?: boolean;
        tags?: string[];
    }): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    bulkDeleteBlogs(body: {
        blogIds: string[];
    }): Promise<{
        success: boolean;
        message: string;
        deleted?: undefined;
    } | {
        success: boolean;
        message: string;
        deleted: number;
    }>;
    bulkUpdateStatus(body: {
        blogIds: string[];
        isPublished: boolean;
    }): Promise<{
        success: boolean;
        message: string;
        updated?: undefined;
    } | {
        success: boolean;
        message: string;
        updated: number;
    }>;
    getAdminBlogs(req: any, scope?: 'own' | 'other' | 'all', status?: string, limit?: string, offset?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: number;
            offset: number;
            hasMore: boolean;
        };
    }>;
    getAdminBlogDetail(req: any, blogId: string): Promise<{
        success: boolean;
        data: any;
    }>;
    updateAdminBlog(req: any, blogId: string, body: any): Promise<{
        success: boolean;
        data: {
            success: boolean;
            message: string;
            data: any;
        };
    }>;
    deleteAdminBlog(req: any, blogId: string): Promise<{
        success: boolean;
        message: string;
    }>;
    submitForApproval(req: any, blogId: string, body: {
        notes?: string;
    }): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    publishBlog(req: any, blogId: string, body: {
        visibility?: 'private' | 'public';
    }): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    unpublishBlog(req: any, blogId: string, body: {
        reason?: string;
    }): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    getAuditLog(req: any, blogId: string, limit?: string): Promise<{
        success: boolean;
        data: {
            id: any;
            action: any;
            initiatedBy: any;
            changes: any;
            createdAt: any;
            initiator: {
                firstName: any;
                lastName: any;
                email: any;
            }[];
        }[];
    }>;
    getSuperAdminBlogs(status?: string, ownerAdminId?: string, limit?: string, offset?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: number;
            offset: number;
            hasMore: boolean;
        };
    }>;
    approveBlog(req: any, blogId: string, body: {
        notes?: string;
    }): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    rejectBlog(req: any, blogId: string, body: {
        reason: string;
    }): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
}
