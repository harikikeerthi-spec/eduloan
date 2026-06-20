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
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthorizationService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../supabase/supabase.service");
let AuthorizationService = class AuthorizationService {
    supabase;
    get db() {
        return this.supabase.getClient();
    }
    constructor(supabase) {
        this.supabase = supabase;
    }
    async canEditBlog(blogId, user) {
        const { data: blog } = await this.db
            .from('Blog')
            .select('authorId')
            .eq('id', blogId)
            .single();
        if (!blog)
            throw new Error('Blog not found');
        if (user.role === 'super_admin')
            return true;
        if (blog.authorId !== user.id) {
            throw new Error("Cannot edit another admin's blog");
        }
        return true;
    }
    async canViewBlog(blogId, user) {
        const { data: blog } = await this.db
            .from('Blog')
            .select('authorId, status, visibility')
            .eq('id', blogId)
            .single();
        if (!blog)
            return false;
        if (user.role === 'super_admin')
            return true;
        if (blog.authorId === user.id)
            return true;
        if (blog.status === 'published' && blog.visibility === 'public')
            return true;
        return false;
    }
    async canDeleteBlog(blogId, user) {
        const { data: blog } = await this.db
            .from('Blog')
            .select('authorId')
            .eq('id', blogId)
            .single();
        if (!blog)
            throw new Error('Blog not found');
        if (user.role === 'super_admin')
            return true;
        if (blog.authorId !== user.id) {
            throw new Error("Cannot delete another admin's blog");
        }
        return true;
    }
    getVisibilityFilter(user, scope) {
        return { role: user.role, userId: user.id, scope };
    }
    getPublicFilter() {
        return {
            isPublished: true,
            visibility: 'public',
        };
    }
};
exports.AuthorizationService = AuthorizationService;
exports.AuthorizationService = AuthorizationService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService])
], AuthorizationService);
//# sourceMappingURL=authorization.service.js.map