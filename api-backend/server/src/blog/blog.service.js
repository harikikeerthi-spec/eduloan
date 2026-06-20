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
exports.BlogService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../supabase/supabase.service");
let BlogService = class BlogService {
    supabase;
    get db() {
        return this.supabase.getClient();
    }
    constructor(supabase) {
        this.supabase = supabase;
    }
    normalizeTagName(tag) {
        return (tag || '').trim().replace(/^#/, '').toLowerCase();
    }
    slugifyTag(tag) {
        return this.normalizeTagName(tag).replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
    }
    async upsertTags(tagNames) {
        const normalized = Array.from(new Set((tagNames || []).map((t) => this.normalizeTagName(t)).filter(Boolean)));
        if (!normalized.length)
            return [];
        return Promise.all(normalized.map(async (name) => {
            const { data: existing } = await this.db.from('Tag').select('id').eq('name', name).single();
            if (existing)
                return existing;
            const { data: created } = await this.db.from('Tag').insert({ name, slug: this.slugifyTag(name) }).select('id').single();
            return created;
        }));
    }
    mapTags(blog) {
        if (!blog)
            return blog;
        return {
            ...blog,
            tags: (blog.tags || []).map((t) => (t.tag ? t.tag.name : t.name || t)),
        };
    }
    async getAllBlogs(options) {
        const { category, featured, limit = 10, offset = 0 } = options || {};
        let query = this.db
            .from('Blog')
            .select('id, title, slug, excerpt, category, authorName, authorImage, authorRole, featuredImage, readTime, views, isFeatured, publishedAt, createdAt, tags:BlogTag(tag:Tag(name))', { count: 'exact' })
            .eq('isPublished', true)
            .order('isFeatured', { ascending: false })
            .order('publishedAt', { ascending: false })
            .range(offset, offset + limit - 1);
        if (category)
            query = query.eq('category', category);
        if (featured !== undefined)
            query = query.eq('isFeatured', featured);
        const { data: blogs, count } = await query;
        return {
            success: true,
            data: (blogs || []).map((b) => this.mapTags(b)),
            pagination: { total: count || 0, limit, offset, hasMore: offset + (blogs?.length || 0) < (count || 0) },
        };
    }
    async getFeaturedBlog() {
        const { data: blog } = await this.db
            .from('Blog')
            .select('id, title, slug, excerpt, category, authorName, authorImage, authorRole, featuredImage, readTime, views, publishedAt, tags:BlogTag(tag:Tag(name))')
            .eq('isPublished', true)
            .eq('isFeatured', true)
            .order('publishedAt', { ascending: false })
            .limit(1)
            .single();
        if (!blog)
            return { success: false, message: 'No featured blog found', data: null };
        return { success: true, data: this.mapTags(blog) };
    }
    async getBlogBySlug(slug) {
        const { data: blog } = await this.db
            .from('Blog')
            .select('id, title, slug, excerpt, content, category, authorName, authorImage, authorRole, featuredImage, readTime, views, publishedAt, createdAt, updatedAt, tags:BlogTag(tag:Tag(name)), comments:Comment(id, author, content, createdAt)')
            .eq('slug', slug)
            .single();
        if (!blog)
            throw new common_1.NotFoundException('Blog not found');
        this.db.from('Blog').update({ views: (blog.views || 0) + 1 }).eq('slug', slug).then(() => { });
        return { success: true, data: this.mapTags(blog) };
    }
    async getBlogById(id) {
        const { data: blog } = await this.db
            .from('Blog')
            .select('id, title, slug, excerpt, content, category, authorName, authorImage, authorRole, featuredImage, readTime, views, isFeatured, isPublished, publishedAt, createdAt, updatedAt, tags:BlogTag(tag:Tag(name))')
            .eq('id', id)
            .single();
        if (!blog)
            throw new common_1.NotFoundException('Blog not found');
        return { success: true, data: this.mapTags(blog) };
    }
    async getPopularBlogs(limit = 10) {
        const { data: blogs } = await this.db
            .from('Blog')
            .select('id, title, slug, excerpt, category, authorName, authorImage, featuredImage, readTime, views, publishedAt, tags:BlogTag(tag:Tag(name))')
            .eq('isPublished', true)
            .order('views', { ascending: false })
            .limit(limit);
        return { success: true, data: (blogs || []).map((b) => this.mapTags(b)) };
    }
    async getBlogStats(id) {
        const { data: blog } = await this.db
            .from('Blog')
            .select('id, title, slug, views, category, publishedAt, createdAt, updatedAt, isFeatured, isPublished')
            .eq('id', id)
            .single();
        if (!blog)
            throw new common_1.NotFoundException('Blog not found');
        return {
            success: true,
            data: {
                ...blog,
                daysSincePublished: blog.publishedAt
                    ? Math.floor((Date.now() - new Date(blog.publishedAt).getTime()) / (1000 * 60 * 60 * 24))
                    : null,
            },
        };
    }
    async incrementBlogView(id) {
        const { data: blog } = await this.db.from('Blog').select('views').eq('id', id).single();
        if (!blog)
            throw new common_1.NotFoundException('Blog not found');
        const { data: updated } = await this.db.from('Blog').update({ views: (blog.views || 0) + 1 }).eq('id', id).select('views').single();
        return { success: true, views: updated?.views };
    }
    async getCategories() {
        const { data: blogs } = await this.db.from('Blog').select('category').eq('isPublished', true);
        const counts = {};
        for (const b of blogs || []) {
            counts[b.category] = (counts[b.category] || 0) + 1;
        }
        return { success: true, data: Object.entries(counts).map(([name, count]) => ({ name, count })) };
    }
    async getRelatedBlogs(category, excludeSlug, limit = 3) {
        const { data: blogs } = await this.db
            .from('Blog')
            .select('id, title, slug, excerpt, category, featuredImage, readTime, publishedAt, tags:BlogTag(tag:Tag(name))')
            .eq('isPublished', true)
            .eq('category', category)
            .neq('slug', excludeSlug)
            .order('publishedAt', { ascending: false })
            .limit(limit);
        return { success: true, data: (blogs || []).map((b) => this.mapTags(b)) };
    }
    async createBlog(data) {
        if (!data.slug) {
            data.slug = data.title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
        }
        const { tags = [], ...rest } = data;
        const { data: blog, error } = await this.db
            .from('Blog')
            .insert({
            ...rest,
            publishedAt: rest.isPublished ? new Date().toISOString() : null,
        })
            .select('id, title, slug, excerpt, content, category, authorName, authorImage, authorRole, featuredImage, readTime, isFeatured, isPublished, publishedAt, createdAt')
            .single();
        if (error)
            throw error;
        if (tags.length > 0) {
            const tagRecords = await this.upsertTags(tags);
            await this.db.from('BlogTag').insert(tagRecords.filter(Boolean).map((t) => ({ blogId: blog.id, tagId: t.id })));
        }
        const { data: finalBlog } = await this.db
            .from('Blog')
            .select('*, tags:BlogTag(tag:Tag(name))')
            .eq('id', blog.id)
            .single();
        return { success: true, message: 'Blog created successfully', data: this.mapTags(finalBlog) };
    }
    async updateBlog(id, data) {
        const { data: existingBlog } = await this.db.from('Blog').select('id, publishedAt').eq('id', id).single();
        if (!existingBlog)
            throw new common_1.NotFoundException('Blog not found');
        const { tags, ...rest } = data;
        const updateData = { ...rest };
        if (data.isPublished && !existingBlog.publishedAt) {
            updateData.publishedAt = new Date().toISOString();
        }
        await this.db.from('Blog').update(updateData).eq('id', id);
        if (tags !== undefined) {
            const tagRecords = await this.upsertTags(tags);
            await this.db.from('BlogTag').delete().eq('blogId', id);
            if (tagRecords.length) {
                await this.db.from('BlogTag').insert(tagRecords.filter(Boolean).map((t) => ({ blogId: id, tagId: t.id })));
            }
        }
        const { data: blog } = await this.db.from('Blog').select('*, tags:BlogTag(tag:Tag(name))').eq('id', id).single();
        return { success: true, message: 'Blog updated successfully', data: this.mapTags(blog) };
    }
    async deleteBlog(id) {
        const { data: blog } = await this.db.from('Blog').select('id').eq('id', id).single();
        if (!blog)
            throw new common_1.NotFoundException('Blog not found');
        await this.db.from('Blog').delete().eq('id', id);
        return { success: true, message: 'Blog deleted successfully' };
    }
    async searchBlogs(query, limit = 10) {
        const { data: blogs } = await this.db
            .from('Blog')
            .select('id, title, slug, excerpt, category, featuredImage, readTime, publishedAt, tags:BlogTag(tag:Tag(name))')
            .eq('isPublished', true)
            .or(`title.ilike.%${query}%,excerpt.ilike.%${query}%,content.ilike.%${query}%`)
            .order('publishedAt', { ascending: false })
            .limit(limit);
        return { success: true, data: (blogs || []).map((b) => this.mapTags(b)), count: blogs?.length || 0 };
    }
    async getAllTags(limit) {
        const { data: tags } = await this.db
            .from('Tag')
            .select('id, name, slug, blogs:BlogTag(blogId, blog:Blog(isPublished))')
            .order('name', { ascending: true });
        let tagsWithCount = (tags || [])
            .map((tag) => ({
            name: tag.name,
            slug: tag.slug,
            count: (tag.blogs || []).filter((b) => b.blog?.isPublished).length,
        }))
            .filter((t) => t.count > 0)
            .sort((a, b) => b.count - a.count);
        if (limit)
            tagsWithCount = tagsWithCount.slice(0, limit);
        return { success: true, data: tagsWithCount };
    }
    async searchBlogsByTag(tag, limit = 10, offset = 0) {
        const normalizedTag = this.normalizeTagName(tag);
        if (!normalizedTag)
            return { success: true, data: [], count: 0, pagination: { total: 0, limit, offset, hasMore: false } };
        const { data: tagRecord } = await this.db.from('Tag').select('id').eq('name', normalizedTag).single();
        if (!tagRecord)
            return { success: true, data: [], count: 0, pagination: { total: 0, limit, offset, hasMore: false } };
        const { data: blogTags } = await this.db.from('BlogTag').select('blogId').eq('tagId', tagRecord.id);
        const blogIds = (blogTags || []).map((bt) => bt.blogId);
        if (!blogIds.length)
            return { success: true, data: [], count: 0, pagination: { total: 0, limit, offset, hasMore: false } };
        const { data: blogs, count } = await this.db
            .from('Blog')
            .select('id, title, slug, excerpt, category, featuredImage, readTime, publishedAt, tags:BlogTag(tag:Tag(name))', { count: 'exact' })
            .eq('isPublished', true)
            .in('id', blogIds)
            .order('publishedAt', { ascending: false })
            .range(offset, offset + limit - 1);
        return {
            success: true,
            data: (blogs || []).map((b) => this.mapTags(b)),
            count: count || 0,
            pagination: { total: count || 0, limit, offset, hasMore: offset + (blogs?.length || 0) < (count || 0) },
        };
    }
    async addCommentToBlog(blogId, data) {
        const { data: blog } = await this.db.from('Blog').select('id').eq('id', blogId).single();
        if (!blog)
            throw new common_1.NotFoundException('Blog not found');
        const { data: comment, error } = await this.db
            .from('Comment')
            .insert({ blogId, author: data.author, content: data.content })
            .select('id, author, content, createdAt')
            .single();
        if (error)
            throw error;
        return { success: true, message: 'Comment added successfully', data: comment };
    }
    async addReplyToComment(commentId, data) {
        const { data: parent } = await this.db.from('Comment').select('id, blogId').eq('id', commentId).single();
        if (!parent)
            throw new common_1.NotFoundException('Comment not found');
        const { data: reply, error } = await this.db
            .from('Comment')
            .insert({ blogId: parent.blogId, parentId: commentId, author: data.author, content: data.content })
            .select('id, author, content, likes, createdAt')
            .single();
        if (error)
            throw error;
        return { success: true, message: 'Reply added successfully', data: reply };
    }
    async deleteComment(commentId) {
        const { data: comment } = await this.db.from('Comment').select('id').eq('id', commentId).single();
        if (!comment)
            throw new common_1.NotFoundException('Comment not found');
        await this.db.from('CommentLike').delete().eq('commentId', commentId);
        await this.db.from('Comment').delete().eq('parentId', commentId);
        await this.db.from('Comment').delete().eq('id', commentId);
        return { success: true, message: 'Comment deleted successfully' };
    }
    async toggleCommentLike(commentId, userId) {
        const { data: comment } = await this.db.from('Comment').select('id, likes').eq('id', commentId).single();
        if (!comment)
            throw new common_1.NotFoundException('Comment not found');
        const { data: existing } = await this.db
            .from('CommentLike')
            .select('id')
            .eq('commentId', commentId)
            .eq('userId', userId)
            .single();
        const currentLikes = comment.likes || 0;
        if (existing) {
            await this.db.from('CommentLike').delete().eq('id', existing.id);
            await this.db.from('Comment').update({ likes: Math.max(0, currentLikes - 1) }).eq('id', commentId);
            return { success: true, message: 'Comment unliked', liked: false, likesCount: Math.max(0, currentLikes - 1) };
        }
        else {
            await this.db.from('CommentLike').insert({ commentId, userId });
            await this.db.from('Comment').update({ likes: currentLikes + 1 }).eq('id', commentId);
            return { success: true, message: 'Comment liked', liked: true, likesCount: currentLikes + 1 };
        }
    }
    async getCommentsForBlog(blogId, limit = 20, offset = 0) {
        const { data: blog } = await this.db.from('Blog').select('id').eq('id', blogId).single();
        if (!blog)
            throw new common_1.NotFoundException('Blog not found');
        const { data: comments, count } = await this.db
            .from('Comment')
            .select('id, author, content, likes, createdAt, replies:Comment!parentId(id, author, content, likes, createdAt)', { count: 'exact' })
            .eq('blogId', blogId)
            .is('parentId', null)
            .order('createdAt', { ascending: false })
            .range(offset, offset + limit - 1);
        const total = count || 0;
        return {
            success: true,
            data: comments || [],
            pagination: { total, limit, offset, hasMore: offset + (comments?.length || 0) < total },
        };
    }
    async getAllBlogsAdmin(options) {
        const { limit = 50, offset = 0, status, timeRange } = options || {};
        let query = this.db
            .from('Blog')
            .select('id, title, slug, excerpt, content, category, authorName, authorImage, authorRole, featuredImage, readTime, views, isFeatured, isPublished, publishedAt, createdAt, updatedAt, tags:BlogTag(tag:Tag(name))', { count: 'exact' })
            .order('createdAt', { ascending: false })
            .range(offset, offset + limit - 1);
        if (status === 'published')
            query = query.eq('isPublished', true);
        if (status === 'draft')
            query = query.eq('isPublished', false);
        if (timeRange && timeRange !== 'all') {
            const now = new Date();
            let fromDate;
            if (timeRange === 'today')
                fromDate = new Date(now.setHours(0, 0, 0, 0));
            else if (timeRange === 'week')
                fromDate = new Date(now.setDate(now.getDate() - 7));
            else if (timeRange === 'month')
                fromDate = new Date(now.setMonth(now.getMonth() - 1));
            else if (timeRange === 'year')
                fromDate = new Date(now.setFullYear(now.getFullYear() - 1));
            if (fromDate) {
                query = query.gte('createdAt', fromDate.toISOString());
            }
        }
        const { data: blogs, count } = await query;
        return {
            success: true,
            data: (blogs || []).map((b) => this.mapTags(b)),
            pagination: { total: count || 0, limit, offset, hasMore: offset + (blogs?.length || 0) < (count || 0) },
        };
    }
    async getBlogStatistics() {
        const [{ count: total }, { count: published }, { count: draft }, { count: featured }, { data: viewsData },] = await Promise.all([
            this.db.from('Blog').select('*', { count: 'exact', head: true }),
            this.db.from('Blog').select('*', { count: 'exact', head: true }).eq('isPublished', true),
            this.db.from('Blog').select('*', { count: 'exact', head: true }).eq('isPublished', false),
            this.db.from('Blog').select('*', { count: 'exact', head: true }).eq('isFeatured', true).eq('isPublished', true),
            this.db.from('Blog').select('views'),
        ]);
        const totalViews = (viewsData || []).reduce((sum, b) => sum + (b.views || 0), 0);
        return { success: true, data: { total: total || 0, published: published || 0, draft: draft || 0, featured: featured || 0, totalViews } };
    }
    async bulkDeleteBlogs(blogIds) {
        if (!blogIds || blogIds.length === 0)
            return { success: false, message: 'No blog IDs provided' };
        const { error } = await this.db.from('Blog').delete().in('id', blogIds);
        if (error)
            throw error;
        return { success: true, message: `${blogIds.length} blog(s) deleted successfully`, deleted: blogIds.length };
    }
    async bulkUpdateStatus(blogIds, isPublished) {
        if (!blogIds || blogIds.length === 0)
            return { success: false, message: 'No blog IDs provided' };
        const updateData = { isPublished };
        if (isPublished) {
            const { data: withoutDate } = await this.db.from('Blog').select('id').in('id', blogIds).is('publishedAt', null);
            const withoutDateIds = (withoutDate || []).map((b) => b.id);
            if (withoutDateIds.length) {
                await this.db.from('Blog').update({ isPublished: true, publishedAt: new Date().toISOString() }).in('id', withoutDateIds);
            }
            const withDateIds = blogIds.filter((id) => !withoutDateIds.includes(id));
            if (withDateIds.length) {
                await this.db.from('Blog').update({ isPublished: true }).in('id', withDateIds);
            }
            return { success: true, message: `${blogIds.length} blog(s) published successfully`, updated: blogIds.length };
        }
        else {
            await this.db.from('Blog').update({ isPublished: false }).in('id', blogIds);
            return { success: true, message: `${blogIds.length} blog(s) unpublished successfully`, updated: blogIds.length };
        }
    }
    async submitForApproval(blogId, notes) {
        const { data: blog } = await this.db.from('Blog').select('id, status').eq('id', blogId).single();
        if (!blog)
            throw new Error('Blog not found');
        if (blog.status !== 'draft')
            throw new Error('Only draft blogs can be submitted for approval');
        const { data, error } = await this.db
            .from('Blog')
            .update({ status: 'pending', submittedAt: new Date().toISOString() })
            .eq('id', blogId)
            .select()
            .single();
        if (error)
            throw error;
        return data;
    }
    async publishBlog(blogId, visibility = 'public') {
        const { data: blog } = await this.db.from('Blog').select('id').eq('id', blogId).single();
        if (!blog)
            throw new Error('Blog not found');
        const { data, error } = await this.db
            .from('Blog')
            .update({ status: 'published', visibility, isPublished: visibility === 'public', publishedAt: new Date().toISOString() })
            .eq('id', blogId)
            .select()
            .single();
        if (error)
            throw error;
        return data;
    }
    async unpublishBlog(blogId, reason) {
        const { data: blog } = await this.db.from('Blog').select('id, status').eq('id', blogId).single();
        if (!blog)
            throw new Error('Blog not found');
        if (blog.status !== 'published')
            throw new Error('Only published blogs can be unpublished');
        const { data, error } = await this.db
            .from('Blog')
            .update({ status: 'draft', isPublished: false, publishedAt: null })
            .eq('id', blogId)
            .select()
            .single();
        if (error)
            throw error;
        return data;
    }
    async approveBlog(blogId, approvedBy, notes) {
        const { data, error } = await this.db
            .from('Blog')
            .update({ approvedAt: new Date().toISOString(), approvedBy })
            .eq('id', blogId)
            .select()
            .single();
        if (error)
            throw error;
        return data;
    }
    async rejectBlog(blogId, reason) {
        const { data, error } = await this.db
            .from('Blog')
            .update({ status: 'draft', rejectionReason: reason, approvedAt: null, approvedBy: null })
            .eq('id', blogId)
            .select()
            .single();
        if (error)
            throw error;
        return data;
    }
    async getAdminBlogs(filter, options = {}) {
        const { limit = 20, offset = 0 } = options;
        let query = this.db
            .from('Blog')
            .select('id, title, slug, excerpt, category, authorName, authorImage, authorRole, authorId, featuredImage, status, visibility, isPublished, readTime, views, publishedAt, createdAt, updatedAt, tags:BlogTag(tag:Tag(name))', { count: 'exact' })
            .order('updatedAt', { ascending: false })
            .range(offset, offset + limit - 1);
        if (filter.isPublished !== undefined)
            query = query.eq('isPublished', filter.isPublished);
        if (filter.status)
            query = query.eq('status', filter.status);
        if (filter.authorId)
            query = query.eq('authorId', filter.authorId);
        const { data: blogs, count } = await query;
        return {
            success: true,
            data: (blogs || []).map((b) => this.mapTags(b)),
            pagination: { total: count || 0, limit, offset, hasMore: offset + (blogs?.length || 0) < (count || 0) },
        };
    }
    async getAdminBlogDetail(blogId) {
        const { data } = await this.db
            .from('Blog')
            .select('*, tags:BlogTag(tag:Tag(name))')
            .eq('id', blogId)
            .single();
        return data ? this.mapTags(data) : null;
    }
};
exports.BlogService = BlogService;
exports.BlogService = BlogService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService])
], BlogService);
//# sourceMappingURL=blog.service.js.map