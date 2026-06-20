"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BlogController = void 0;
const common_1 = require("@nestjs/common");
const blog_service_1 = require("./blog.service");
const admin_guard_1 = require("../auth/admin.guard");
const staff_guard_1 = require("../auth/staff.guard");
const authorization_service_1 = require("../auth/authorization.service");
const audit_log_service_1 = require("../auth/audit-log.service");
let BlogController = class BlogController {
    blogService;
    authService;
    auditLog;
    constructor(blogService, authService, auditLog) {
        this.blogService = blogService;
        this.authService = authService;
        this.auditLog = auditLog;
    }
    async getAllAuditLogs(entityType, initiatedBy, limit, offset) {
        const logs = await this.auditLog.getAllLogs(entityType, initiatedBy, limit ? parseInt(limit, 10) : 100, offset ? parseInt(offset, 10) : 0);
        return {
            success: true,
            data: logs,
        };
    }
    async getBlogStatistics() {
        return this.blogService.getBlogStatistics();
    }
    async getAllBlogs(category, featured, limit, offset) {
        return this.blogService.getAllBlogs({
            category,
            featured: featured === 'true' ? true : featured === 'false' ? false : undefined,
            limit: limit ? parseInt(limit, 10) : 10,
            offset: offset ? parseInt(offset, 10) : 0,
        });
    }
    async getFeaturedBlog() {
        return this.blogService.getFeaturedBlog();
    }
    async getCategories() {
        return this.blogService.getCategories();
    }
    async searchBlogs(query, limit) {
        return this.blogService.searchBlogs(query || '', limit ? parseInt(limit, 10) : 10);
    }
    async getAllTags(limit) {
        return this.blogService.getAllTags(limit ? parseInt(limit, 10) : undefined);
    }
    async searchBlogsByTag(tag, limit, offset) {
        return this.blogService.searchBlogsByTag(tag, limit ? parseInt(limit, 10) : 10, offset ? parseInt(offset, 10) : 0);
    }
    async getRelatedBlogs(category, excludeSlug, limit) {
        return this.blogService.getRelatedBlogs(category, excludeSlug || '', limit ? parseInt(limit, 10) : 3);
    }
    async getBlogBySlug(slug) {
        return this.blogService.getBlogBySlug(slug);
    }
    async getPopularBlogs(limit) {
        return this.blogService.getPopularBlogs(limit ? parseInt(limit, 10) : 10);
    }
    async getCommentsForBlog(id, limit, offset) {
        return this.blogService.getCommentsForBlog(id, limit ? parseInt(limit, 10) : 20, offset ? parseInt(offset, 10) : 0);
    }
    async addCommentToBlog(id, body) {
        return this.blogService.addCommentToBlog(id, body);
    }
    async addReplyToComment(commentId, body) {
        return this.blogService.addReplyToComment(commentId, body);
    }
    async deleteComment(commentId) {
        return this.blogService.deleteComment(commentId);
    }
    async toggleCommentLike(commentId, body) {
        return this.blogService.toggleCommentLike(commentId, body.userId);
    }
    async getLikedComments(userId) {
        return this.blogService.getLikedComments(userId);
    }
    async getBlogStats(id) {
        return this.blogService.getBlogStats(id);
    }
    async getAllBlogsAdmin(limit, offset, status, timeRange) {
        return this.blogService.getAllBlogsAdmin({
            limit: limit ? parseInt(limit, 10) : 50,
            offset: offset ? parseInt(offset, 10) : 0,
            status,
            timeRange,
        });
    }
    async createBlog(body, req) {
        const blogData = { ...body };
        if (body.authorId) {
            blogData.authorId = body.authorId;
        }
        else if (req.user?.id) {
            blogData.authorId = req.user.id;
        }
        return this.blogService.createBlog(blogData);
    }
    async incrementBlogView(id) {
        return this.blogService.incrementBlogView(id);
    }
    async getBlogById(id) {
        return this.blogService.getBlogById(id);
    }
    async deleteBlog(id) {
        return this.blogService.deleteBlog(id);
    }
    async updateBlog(id, body) {
        return this.blogService.updateBlog(id, body);
    }
    async bulkDeleteBlogs(body) {
        return this.blogService.bulkDeleteBlogs(body.blogIds);
    }
    async bulkUpdateStatus(body) {
        return this.blogService.bulkUpdateStatus(body.blogIds, body.isPublished);
    }
    async getAdminBlogs(req, scope = 'all', status, limit, offset) {
        const filter = this.authService.getVisibilityFilter(req.user, scope);
        if (status) {
            filter.status = status;
        }
        return this.blogService.getAdminBlogs(filter, {
            limit: limit ? parseInt(limit, 10) : 20,
            offset: offset ? parseInt(offset, 10) : 0,
        });
    }
    async getAdminBlogDetail(req, blogId) {
        const canView = await this.authService.canViewBlog(blogId, req.user);
        if (!canView) {
            throw new common_1.ForbiddenException('Cannot access this blog');
        }
        const blog = await this.blogService.getAdminBlogDetail(blogId);
        if (!blog) {
            throw new common_1.NotFoundException('Blog not found');
        }
        const isOwner = blog.authorId === req.user.id;
        blog['readOnly'] = !isOwner && req.user.role !== 'super_admin';
        blog['isOwnContent'] = isOwner;
        return {
            success: true,
            data: blog,
        };
    }
    async updateAdminBlog(req, blogId, body) {
        await this.authService.canEditBlog(blogId, req.user);
        const originalBlog = await this.blogService.getAdminBlogDetail(blogId);
        const updatedBlog = await this.blogService.updateBlog(blogId, body);
        await this.auditLog.logAction('update', 'blog', blogId, req.user, {
            before: originalBlog,
            after: updatedBlog,
        }, req);
        return {
            success: true,
            data: updatedBlog,
        };
    }
    async deleteAdminBlog(req, blogId) {
        await this.authService.canDeleteBlog(blogId, req.user);
        const blog = await this.blogService.getAdminBlogDetail(blogId);
        await this.blogService.deleteBlog(blogId);
        await this.auditLog.logAction('delete', 'blog', blogId, req.user, { deletedBlog: blog }, req);
        return {
            success: true,
            message: 'Blog deleted successfully',
        };
    }
    async submitForApproval(req, blogId, body) {
        await this.authService.canEditBlog(blogId, req.user);
        const blog = await this.blogService.submitForApproval(blogId, body.notes);
        await this.auditLog.logAction('submit_for_approval', 'blog', blogId, req.user, { notes: body.notes }, req);
        return {
            success: true,
            message: 'Blog submitted for approval',
            data: blog,
        };
    }
    async publishBlog(req, blogId, body) {
        await this.authService.canEditBlog(blogId, req.user);
        const blog = await this.blogService.publishBlog(blogId, body.visibility || 'public');
        await this.auditLog.logAction('publish', 'blog', blogId, req.user, { visibility: body.visibility }, req);
        return {
            success: true,
            message: 'Blog published successfully',
            data: blog,
        };
    }
    async unpublishBlog(req, blogId, body) {
        await this.authService.canEditBlog(blogId, req.user);
        const blog = await this.blogService.unpublishBlog(blogId, body.reason);
        await this.auditLog.logAction('unpublish', 'blog', blogId, req.user, { reason: body.reason }, req);
        return {
            success: true,
            message: 'Blog unpublished successfully',
            data: blog,
        };
    }
    async getAuditLog(req, blogId, limit) {
        const blog = await this.blogService.getAdminBlogDetail(blogId);
        if (!blog) {
            throw new common_1.NotFoundException('Blog not found');
        }
        const isOwner = blog.authorId === req.user.id;
        if (!isOwner && req.user.role !== 'super_admin') {
            throw new common_1.ForbiddenException('Cannot view audit log for another admin\'s blog');
        }
        const logs = await this.auditLog.getEntityLogs('blog', blogId, limit ? parseInt(limit, 10) : 50);
        return {
            success: true,
            data: logs,
        };
    }
    async getSuperAdminBlogs(status, ownerAdminId, limit, offset) {
        const filter = {};
        if (status) {
            filter.status = status;
        }
        if (ownerAdminId) {
            filter.authorId = ownerAdminId;
        }
        return this.blogService.getAdminBlogs(filter, {
            limit: limit ? parseInt(limit, 10) : 50,
            offset: offset ? parseInt(offset, 10) : 0,
        });
    }
    async approveBlog(req, blogId, body) {
        const blog = await this.blogService.approveBlog(blogId, req.user.id, body.notes);
        await this.auditLog.logAction('approve', 'blog', blogId, req.user, { notes: body.notes }, req);
        return {
            success: true,
            message: 'Blog approved',
            data: blog,
        };
    }
    async rejectBlog(req, blogId, body) {
        const blog = await this.blogService.rejectBlog(blogId, body.reason);
        await this.auditLog.logAction('reject', 'blog', blogId, req.user, { reason: body.reason }, req);
        return {
            success: true,
            message: 'Blog rejected',
            data: blog,
        };
    }
};
exports.BlogController = BlogController;
__decorate([
    (0, common_1.Get)('admin/matrix-logs'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Query)('entityType')),
    __param(1, (0, common_1.Query)('initiatedBy')),
    __param(2, (0, common_1.Query)('limit')),
    __param(3, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getAllAuditLogs", null);
__decorate([
    (0, common_1.Get)('admin/stats'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getBlogStatistics", null);
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Query)('category')),
    __param(1, (0, common_1.Query)('featured')),
    __param(2, (0, common_1.Query)('limit')),
    __param(3, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getAllBlogs", null);
__decorate([
    (0, common_1.Get)('featured'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getFeaturedBlog", null);
__decorate([
    (0, common_1.Get)('categories'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getCategories", null);
__decorate([
    (0, common_1.Get)('search'),
    __param(0, (0, common_1.Query)('q')),
    __param(1, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "searchBlogs", null);
__decorate([
    (0, common_1.Get)('tags'),
    __param(0, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getAllTags", null);
__decorate([
    (0, common_1.Get)('tags/:tag'),
    __param(0, (0, common_1.Param)('tag')),
    __param(1, (0, common_1.Query)('limit')),
    __param(2, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "searchBlogsByTag", null);
__decorate([
    (0, common_1.Get)('related/:category'),
    __param(0, (0, common_1.Param)('category')),
    __param(1, (0, common_1.Query)('exclude')),
    __param(2, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getRelatedBlogs", null);
__decorate([
    (0, common_1.Get)('slug/:slug'),
    __param(0, (0, common_1.Param)('slug')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getBlogBySlug", null);
__decorate([
    (0, common_1.Get)('popular'),
    __param(0, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getPopularBlogs", null);
__decorate([
    (0, common_1.Get)(':id/comments'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Query)('limit')),
    __param(2, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getCommentsForBlog", null);
__decorate([
    (0, common_1.Post)(':id/comments'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "addCommentToBlog", null);
__decorate([
    (0, common_1.Post)('comments/:commentId/replies'),
    __param(0, (0, common_1.Param)('commentId')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "addReplyToComment", null);
__decorate([
    (0, common_1.Delete)('comments/:commentId'),
    __param(0, (0, common_1.Param)('commentId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "deleteComment", null);
__decorate([
    (0, common_1.Post)('comments/:commentId/like'),
    __param(0, (0, common_1.Param)('commentId')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "toggleCommentLike", null);
__decorate([
    (0, common_1.Get)('comments/likes/:userId'),
    __param(0, (0, common_1.Param)('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getLikedComments", null);
__decorate([
    (0, common_1.Get)(':id/stats'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getBlogStats", null);
__decorate([
    (0, common_1.Get)('admin/all'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Query)('limit')),
    __param(1, (0, common_1.Query)('offset')),
    __param(2, (0, common_1.Query)('status')),
    __param(3, (0, common_1.Query)('timeRange')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getAllBlogsAdmin", null);
__decorate([
    (0, common_1.Post)(),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "createBlog", null);
__decorate([
    (0, common_1.Post)(':id/view'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "incrementBlogView", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getBlogById", null);
__decorate([
    (0, common_1.Delete)(':id'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "deleteBlog", null);
__decorate([
    (0, common_1.Put)(':id'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "updateBlog", null);
__decorate([
    (0, common_1.Post)('admin/bulk-delete'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "bulkDeleteBlogs", null);
__decorate([
    (0, common_1.Post)('admin/bulk-status'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "bulkUpdateStatus", null);
__decorate([
    (0, common_1.Get)('admin/list'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('scope')),
    __param(2, (0, common_1.Query)('status')),
    __param(3, (0, common_1.Query)('limit')),
    __param(4, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String, String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getAdminBlogs", null);
__decorate([
    (0, common_1.Get)('admin/:id'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getAdminBlogDetail", null);
__decorate([
    (0, common_1.Put)('admin/:id'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "updateAdminBlog", null);
__decorate([
    (0, common_1.Delete)('admin/:id'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "deleteAdminBlog", null);
__decorate([
    (0, common_1.Post)('admin/:id/submit-for-approval'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "submitForApproval", null);
__decorate([
    (0, common_1.Post)('admin/:id/publish'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "publishBlog", null);
__decorate([
    (0, common_1.Post)('admin/:id/unpublish'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "unpublishBlog", null);
__decorate([
    (0, common_1.Get)('admin/:id/audit-log'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getAuditLog", null);
__decorate([
    (0, common_1.Get)('super-admin/all'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Query)('status')),
    __param(1, (0, common_1.Query)('owner')),
    __param(2, (0, common_1.Query)('limit')),
    __param(3, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "getSuperAdminBlogs", null);
__decorate([
    (0, common_1.Post)('super-admin/:id/approve'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "approveBlog", null);
__decorate([
    (0, common_1.Post)('super-admin/:id/reject'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], BlogController.prototype, "rejectBlog", null);
exports.BlogController = BlogController = __decorate([
    (0, common_1.Controller)('blogs'),
    __metadata("design:paramtypes", [blog_service_1.BlogService,
        authorization_service_1.AuthorizationService,
        audit_log_service_1.AuditLogService])
], BlogController);
//# sourceMappingURL=blog.controller.js.map