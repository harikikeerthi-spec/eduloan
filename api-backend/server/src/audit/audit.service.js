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
exports.AuditService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../supabase/supabase.service");
let AuditService = class AuditService {
    supabase;
    get db() {
        return this.supabase.getClient();
    }
    constructor(supabase) {
        this.supabase = supabase;
    }
    async getRecentActivity(limit = 20) {
        try {
            const [appsRes, blogsRes, postsRes, usersRes, mentorsRes,] = await Promise.all([
                this.db.from('LoanApplication').select('id, applicationNumber, status, submittedAt, user:User!userId(firstName, lastName)').order('submittedAt', { ascending: false }).limit(limit),
                this.db.from('Blog').select('id, title, authorName, publishedAt, createdAt').eq('isPublished', true).order('publishedAt', { ascending: false }).limit(limit),
                this.db.from('ForumPost').select('id, title, createdAt, author:User!authorId(firstName, lastName)').order('createdAt', { ascending: false }).limit(limit),
                this.db.from('User').select('id, firstName, lastName, email, createdAt').order('createdAt', { ascending: false }).limit(limit),
                this.db.from('Mentor').select('id, name, expertise, createdAt').order('createdAt', { ascending: false }).limit(limit),
            ]);
            const applications = appsRes.data || [];
            const blogs = blogsRes.data || [];
            const forumPosts = postsRes.data || [];
            const users = usersRes.data || [];
            const mentors = mentorsRes.data || [];
            if (appsRes.error)
                console.error('[AuditService] App query error:', appsRes.error);
            if (blogsRes.error)
                console.error('[AuditService] Blog query error:', blogsRes.error);
            if (postsRes.error)
                console.error('[AuditService] Forum query error:', postsRes.error);
            if (usersRes.error)
                console.error('[AuditService] User query error:', usersRes.error);
            if (mentorsRes.error)
                console.error('[AuditService] Mentor query error:', mentorsRes.error);
            const formatName = (f, l) => `${f || ''} ${l || ''}`.trim() || 'Unknown User';
            const activities = [
                ...(applications || []).map((app) => ({
                    id: app.id,
                    type: 'application',
                    title: `Application #${app.applicationNumber}`,
                    description: `${formatName(app.user?.firstName, app.user?.lastName)} - ${app.status}`,
                    status: app.status,
                    date: app.submittedAt,
                    link: '#',
                })),
                ...(blogs || []).map((blog) => ({
                    id: blog.id,
                    type: 'blog',
                    title: `Blog Published: ${blog.title}`,
                    description: `By ${blog.authorName}`,
                    status: 'published',
                    date: blog.publishedAt || blog.createdAt,
                    link: `/blog/${blog.id}`,
                })),
                ...(forumPosts || []).map((post) => ({
                    id: post.id,
                    type: 'forum',
                    title: `Forum Post: ${post.title}`,
                    description: `By ${formatName(post.author?.firstName, post.author?.lastName)}`,
                    status: 'discussion',
                    date: post.createdAt,
                    link: `/community/forum/${post.id}`,
                })),
                ...(users || []).map((user) => ({
                    id: user.id,
                    type: 'user',
                    title: `New User Joined`,
                    description: `${formatName(user.firstName, user.lastName)} (${user.email})`,
                    status: 'active',
                    date: user.createdAt,
                    link: `/user/${user.id}`,
                })),
                ...(mentors || []).map((mentor) => ({
                    id: mentor.id,
                    type: 'mentor',
                    title: `New Mentor Profile`,
                    description: `${mentor.name} - ${(mentor.expertise || []).join(', ')}`,
                    status: 'pending',
                    date: mentor.createdAt,
                    link: `/mentor/${mentor.id}`,
                })),
            ];
            return activities
                .sort((a, b) => {
                const dateA = a.date ? new Date(a.date).getTime() : 0;
                const dateB = b.date ? new Date(b.date).getTime() : 0;
                return dateB - dateA;
            })
                .slice(0, limit);
        }
        catch (error) {
            console.error('[AuditService.getRecentActivity] Fatal error:', error);
            return [];
        }
    }
};
exports.AuditService = AuditService;
exports.AuditService = AuditService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService])
], AuditService);
//# sourceMappingURL=audit.service.js.map