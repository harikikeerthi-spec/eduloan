// @ts-nocheck
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class BlogService {
    constructor(private prisma: PrismaService) { }

    private normalizeTagName(tag: string) {
        return (tag || '')
            .trim()
            .replace(/^#/, '')
            .toLowerCase();
    }

    private slugifyTag(tag: string) {
        const normalized = this.normalizeTagName(tag);
        return normalized
            .replace(/[^a-z0-9]+/g, '-')
            .replace(/(^-|-$)/g, '');
    }

    private async upsertTags(tagNames: string[]) {
        const normalized = Array.from(
            new Set((tagNames || []).map((t) => this.normalizeTagName(t)).filter(Boolean)),
        );

        if (!normalized.length) {
            return [];
        }

        return Promise.all(
            normalized.map((name) =>
                this.prisma.tag.upsert({
                    where: { name },
                    update: {},
                    create: { name, slug: this.slugifyTag(name) },
                }),
            ),
        );
    }

    private mapTags(blog: any) {
        if (!blog) return blog;
        return {
            ...blog,
            tags: (blog.tags || []).map((t: any) => t.tag.name),
        };
    }

    /**
     * Get all published blogs with basic info (title, excerpt, category, etc.)
     * Used for blog listing page
     */
    async getAllBlogs(options?: {
        category?: string;
        featured?: boolean;
        limit?: number;
        offset?: number;
    }) {
        const { category, featured, limit = 10, offset = 0 } = options || {};

        const where: any = {
            isPublished: true,
        };

        if (category) {
            where.category = category;
        }

        if (featured !== undefined) {
            where.isFeatured = featured;
        }

        const blogs = await this.prisma.blog.findMany({
            where,
            select: {
                id: true,
                title: true,
                slug: true,
                excerpt: true,
                category: true,
                authorName: true,
                authorImage: true,
                authorRole: true,
                featuredImage: true,
                readTime: true,
                views: true,
                isFeatured: true,
                publishedAt: true,
                createdAt: true,
                tags: {
                    select: {
                        tag: {
                            select: { name: true },
                        },
                    },
                },
            },
            orderBy: [
                { isFeatured: 'desc' },
                { publishedAt: 'desc' },
            ],
            take: limit,
            skip: offset,
        });

        const total = await this.prisma.blog.count({ where });

        return {
            success: true,
            data: blogs.map((blog) => this.mapTags(blog)),
            pagination: {
                total,
                limit,
                offset,
                hasMore: offset + blogs.length < total,
            },
        };
    }

    /**
     * Get featured blog (for homepage/blog listing hero)
     */
    async getFeaturedBlog() {
        const blog = await this.prisma.blog.findFirst({
            where: {
                isPublished: true,
                isFeatured: true,
            },
            select: {
                id: true,
                title: true,
                slug: true,
                excerpt: true,
                category: true,
                authorName: true,
                authorImage: true,
                authorRole: true,
                featuredImage: true,
                readTime: true,
                views: true,
                publishedAt: true,
                tags: {
                    select: {
                        tag: {
                            select: { name: true },
                        },
                    },
                },
            },
            orderBy: {
                publishedAt: 'desc',
            },
        });

        if (!blog) {
            return {
                success: false,
                message: 'No featured blog found',
                data: null,
            };
        }

        return {
            success: true,
            data: this.mapTags(blog),
        };
    }

    /**
     * Get full blog by slug (for individual blog page)
     * Includes full content
     */
    async getBlogBySlug(slug: string) {
        const blog = await this.prisma.blog.findUnique({
            where: { slug },
            select: {
                id: true,
                title: true,
                slug: true,
                excerpt: true,
                content: true,
                category: true,
                authorName: true,
                authorImage: true,
                authorRole: true,
                featuredImage: true,
                readTime: true,
                views: true,
                publishedAt: true,
                createdAt: true,
                updatedAt: true,
                tags: {
                    select: {
                        tag: {
                            select: { name: true },
                        },
                    },
                },
                comments: {
                    orderBy: { createdAt: 'desc' },
                    select: {
                        id: true,
                        author: true,
                        content: true,
                        createdAt: true,
                        likes: true,
                        parentId: true,
                        replies: {
                            orderBy: { createdAt: 'asc' },
                            select: {
                                id: true,
                                author: true,
                                content: true,
                                createdAt: true,
                                likes: true,
                                parentId: true,
                            },
                        },
                    },
                },
            },
        });

        if (!blog) {
            throw new NotFoundException('Blog not found');
        }

        // Increment view count
        await this.prisma.blog.update({
            where: { slug },
            data: { views: { increment: 1 } },
        });

        return {
            success: true,
            data: this.mapTags(blog),
        };
    }


    /**
     * Get blog by ID
     */
    async getBlogById(id: string) {
        const blog = await this.prisma.blog.findUnique({
            where: { id },
            select: {
                id: true,
                title: true,
                slug: true,
                excerpt: true,
                content: true,
                category: true,
                authorName: true,
                authorImage: true,
                authorRole: true,
                featuredImage: true,
                readTime: true,
                views: true,
                isFeatured: true,
                isPublished: true,
                publishedAt: true,
                createdAt: true,
                updatedAt: true,
                tags: {
                    select: {
                        tag: {
                            select: { name: true },
                        },
                    },
                },
            },
        });

        if (!blog) {
            throw new NotFoundException('Blog not found');
        }

        return {
            success: true,
            data: this.mapTags(blog),
        };
    }

    /**
     * Get most popular blogs by view count
     */
    async getPopularBlogs(limit = 10) {
        const blogs = await this.prisma.blog.findMany({
            where: {
                isPublished: true,
            },
            select: {
                id: true,
                title: true,
                slug: true,
                excerpt: true,
                category: true,
                authorName: true,
                authorImage: true,
                featuredImage: true,
                readTime: true,
                views: true,
                publishedAt: true,
                tags: {
                    select: {
                        tag: {
                            select: { name: true },
                        },
                    },
                },
            },
            orderBy: {
                views: 'desc',
            },
            take: limit,
        });

        return {
            success: true,
            data: blogs.map((blog) => this.mapTags(blog)),
        };
    }

    /**
     * Get blog statistics
     */
    async getBlogStats(id: string) {
        const blog = await this.prisma.blog.findUnique({
            where: { id },
            select: {
                id: true,
                title: true,
                slug: true,
                views: true,
                category: true,
                publishedAt: true,
                createdAt: true,
                updatedAt: true,
                isFeatured: true,
                isPublished: true,
            },
        });

        if (!blog) {
            throw new NotFoundException('Blog not found');
        }

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

    /**
     * Manually increment blog view count
     */
    async incrementBlogView(id: string) {
        const blog = await this.prisma.blog.findUnique({
            where: { id },
        });

        if (!blog) {
            throw new NotFoundException('Blog not found');
        }

        const updated = await this.prisma.blog.update({
            where: { id },
            data: { views: { increment: 1 } },
            select: { views: true },
        });

        return {
            success: true,
            views: updated.views,
        };
    }

    /**
     * Get all categories with blog count
     */
    async getCategories() {
        const categories = await this.prisma.blog.groupBy({
            by: ['category'],
            where: {
                isPublished: true,
            },
            _count: {
                category: true,
            },
        });

        return {
            success: true,
            data: categories.map((c) => ({
                name: c.category,
                count: c._count.category,
            })),
        };
    }

    /**
     * Get related blogs by category (excluding current blog)
     */
    async getRelatedBlogs(category: string, excludeSlug: string, limit = 3) {
        const blogs = await this.prisma.blog.findMany({
            where: {
                isPublished: true,
                category,
                slug: { not: excludeSlug },
            },
            select: {
                id: true,
                title: true,
                slug: true,
                excerpt: true,
                category: true,
                featuredImage: true,
                readTime: true,
                publishedAt: true,
                tags: {
                    select: {
                        tag: {
                            select: { name: true },
                        },
                    },
                },
            },
            orderBy: {
                publishedAt: 'desc',
            },
            take: limit,
        });

        return {
            success: true,
            data: blogs.map((blog) => this.mapTags(blog)),
        };
    }

    /**
     * Create a new blog post
     */
    async createBlog(data: {
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
    }) {
        // Generate slug from title if not provided
        if (!data.slug) {
            data.slug = data.title
                .toLowerCase()
                .replace(/[^a-z0-9]+/g, '-')
                .replace(/(^-|-$)/g, '');
        }

        const { isPublished, isFeatured, tags = [], ...rest } = data as any;
        const tagRecords = await this.upsertTags(tags);
        const blog = await this.prisma.blog.create({
            data: {
                ...rest,
                isPublished,
                isFeatured,
                publishedAt: isPublished ? new Date() : null,
                tags: tagRecords.length
                    ? {
                        create: tagRecords.map((tag) => ({
                            tag: {
                                connect: { id: tag.id },
                            },
                        })),
                    }
                    : undefined,
            },
            select: {
                id: true,
                title: true,
                slug: true,
                excerpt: true,
                content: true,
                category: true,
                authorName: true,
                authorImage: true,
                authorRole: true,
                featuredImage: true,
                readTime: true,
                isFeatured: true,
                isPublished: true,
                publishedAt: true,
                createdAt: true,
                tags: {
                    select: {
                        tag: { select: { name: true } },
                    },
                },
            },
        });

        return {
            success: true,
            message: 'Blog created successfully',
            data: this.mapTags(blog),
        };
    }

    /**
     * Update a blog post
     */
    async updateBlog(
        id: string,
        data: {
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
        },
    ) {
        const existingBlog = await this.prisma.blog.findUnique({
            where: { id },
        });

        if (!existingBlog) {
            throw new NotFoundException('Blog not found');
        }

        // Set publishedAt if publishing for the first time
        if (data.isPublished && !existingBlog.publishedAt) {
            (data as any).publishedAt = new Date();
        }

        const { isPublished, isFeatured, tags, ...rest } = data as any;
        const updateData: any = { ...rest };
        if (isPublished !== undefined) updateData.isPublished = isPublished;
        if (isFeatured !== undefined) updateData.isFeatured = isFeatured;

        await this.prisma.blog.update({
            where: { id },
            data: updateData,
        });

        if (tags !== undefined) {
            const tagRecords = await this.upsertTags(tags);
            await this.prisma.blogTag.deleteMany({ where: { blogId: id } });

            if (tagRecords.length) {
                await this.prisma.blogTag.createMany({
                    data: tagRecords.map((tag) => ({ blogId: id, tagId: tag.id })),
                });
            }
        }

        const blog = await this.prisma.blog.findUnique({
            where: { id },
            select: {
                id: true,
                title: true,
                slug: true,
                excerpt: true,
                content: true,
                category: true,
                authorName: true,
                authorImage: true,
                authorRole: true,
                featuredImage: true,
                readTime: true,
                isFeatured: true,
                isPublished: true,
                publishedAt: true,
                createdAt: true,
                updatedAt: true,
                tags: {
                    select: {
                        tag: { select: { name: true } },
                    },
                },
            },
        });

        return {
            success: true,
            message: 'Blog updated successfully',
            data: this.mapTags(blog),
        };
    }

    /**
     * Delete a blog post
     */
    async deleteBlog(id: string) {
        const blog = await this.prisma.blog.findUnique({
            where: { id },
        });

        if (!blog) {
            throw new NotFoundException('Blog not found');
        }

        await this.prisma.blog.delete({
            where: { id },
        });

        return {
            success: true,
            message: 'Blog deleted successfully',
        };
    }

    /**
     * Search blogs by title or content
     */
    async searchBlogs(query: string, limit = 10) {
        const blogs = await this.prisma.blog.findMany({
            where: {
                isPublished: true,
                OR: [
                    { title: { contains: query, mode: 'insensitive' } },
                    { excerpt: { contains: query, mode: 'insensitive' } },
                    { content: { contains: query, mode: 'insensitive' } },
                ],
            },
            select: {
                id: true,
                title: true,
                slug: true,
                excerpt: true,
                category: true,
                featuredImage: true,
                readTime: true,
                publishedAt: true,
                tags: {
                    select: {
                        tag: {
                            select: { name: true },
                        },
                    },
                },
            },
            orderBy: {
                publishedAt: 'desc',
            },
            take: limit,
        });

        return {
            success: true,
            data: blogs.map((blog) => this.mapTags(blog)),
            count: blogs.length,
        };
    }

    /**
     * Get all tags with usage count
     */
    async getAllTags(limit?: number) {
        // Get all tags with their blog count
        const tags = await this.prisma.tag.findMany({
            select: {
                id: true,
                name: true,
                slug: true,
                blogs: {
                    where: {
                        blog: {
                            isPublished: true,
                        },
                    },
                    select: {
                        blogId: true,
                    },
                },
            },
            orderBy: {
                name: 'asc',
            },
        });

        // Count blogs per tag and sort by count
        let tagsWithCount = tags
            .map((tag) => ({
                name: tag.name,
                slug: tag.slug,
                count: tag.blogs.length,
            }))
            .filter((tag) => tag.count > 0) // Only return tags used in published blogs
            .sort((a, b) => b.count - a.count);

        // Apply limit if specified
        if (limit) {
            tagsWithCount = tagsWithCount.slice(0, limit);
        }

        return {
            success: true,
            data: tagsWithCount,
        };
    }

    /**
     * Search blogs by tag name (handles #tag syntax)
     */
    async searchBlogsByTag(tag: string, limit = 10, offset = 0) {
        const normalizedTag = this.normalizeTagName(tag);

        if (!normalizedTag) {
            return {
                success: true,
                data: [],
                count: 0,
                pagination: { total: 0, limit, offset, hasMore: false },
            };
        }

        const where = {
            isPublished: true,
            tags: {
                some: {
                    tag: { name: normalizedTag },
                },
            },
        } as const;

        const [blogs, total] = await Promise.all([
            this.prisma.blog.findMany({
                where,
                select: {
                    id: true,
                    title: true,
                    slug: true,
                    excerpt: true,
                    category: true,
                    featuredImage: true,
                    readTime: true,
                    publishedAt: true,
                    tags: {
                        select: {
                            tag: { select: { name: true } },
                        },
                    },
                },
                orderBy: { publishedAt: 'desc' },
                take: limit,
                skip: offset,
            }),
            this.prisma.blog.count({ where }),
        ]);

        return {
            success: true,
            data: blogs.map((blog) => this.mapTags(blog)),
            count: total,
            pagination: {
                total,
                limit,
                offset,
                hasMore: offset + blogs.length < total,
            },
        };
    }

    /**
     * Add a new comment to a blog
     */
    async addCommentToBlog(
        blogId: string,
        data: {
            author: string;
            content: string;
        },
    ) {
        const blog = await this.prisma.blog.findUnique({
            where: { id: blogId },
            select: { id: true },
        });

        if (!blog) {
            throw new NotFoundException('Blog not found');
        }

        const comment = await this.prisma.comment.create({
            data: {
                blogId,
                author: data.author,
                content: data.content,
            },
            select: {
                id: true,
                author: true,
                content: true,
                createdAt: true,
            },
        });

        return {
            success: true,
            message: 'Comment added successfully',
            data: comment,
        };
    }

    /**
     * Get comments for a blog with pagination
     */
    async getCommentsForBlog(blogId: string, limit = 20, offset = 0) {
        const blog = await this.prisma.blog.findUnique({
            where: { id: blogId },
            select: { id: true },
        });

        if (!blog) {
            throw new NotFoundException('Blog not found');
        }

        const [comments, total] = await Promise.all([
            this.prisma.comment.findMany({
                where: { blogId },
                orderBy: { createdAt: 'desc' },
                take: limit,
                skip: offset,
                select: {
                    id: true,
                    author: true,
                    content: true,
                    createdAt: true,
                },
            }),
            this.prisma.comment.count({ where: { blogId } }),
        ]);

        return {
            success: true,
            data: comments,
            pagination: {
                total,
                limit,
                offset,
                hasMore: offset + comments.length < total,
            },
        };
    }

    /**
     * Add a comment to a blog post
     */
    async addCommentToBlog(
        blogId: string,
        body: { author: string; content: string },
    ) {
        // Verify blog exists
        const blog = await this.prisma.blog.findUnique({
            where: { id: blogId },
            select: { id: true },
        });

        if (!blog) {
            throw new NotFoundException('Blog not found');
        }

        // Create the comment
        const comment = await this.prisma.comment.create({
            data: {
                blogId,
                author: body.author,
                content: body.content,
            },
            select: {
                id: true,
                author: true,
                content: true,
                createdAt: true,
            },
        });

        return {
            success: true,
            message: 'Comment added successfully',
            data: comment,
        };
    }

    /**
     * Delete a comment from a blog post
     */
    async deleteComment(commentId: string) {
        const comment = await this.prisma.comment.findUnique({
            where: { id: commentId },
            select: { id: true, parentId: true },
        });

        if (!comment) {
            throw new NotFoundException('Comment not found');
        }

        // If this is a reply (has parentId), just delete this comment and its likes
        if (comment.parentId) {
            await this.prisma.$transaction([
                // Delete likes for this reply
                this.prisma.commentLike.deleteMany({
                    where: { commentId },
                }),
                // Delete the reply itself
                this.prisma.comment.delete({
                    where: { id: commentId },
                }),
            ]);
        } else {
            // This is a parent comment, delete it along with all replies and their likes
            // Get all reply IDs first
            const replies = await this.prisma.comment.findMany({
                where: { parentId: commentId },
                select: { id: true },
            });
            const replyIds = replies.map(r => r.id);

            await this.prisma.$transaction([
                // 1. Delete likes for all replies
                this.prisma.commentLike.deleteMany({
                    where: { commentId: { in: replyIds } },
                }),
                // 2. Delete likes for the parent comment
                this.prisma.commentLike.deleteMany({
                    where: { commentId },
                }),
                // 3. Delete all replies
                this.prisma.comment.deleteMany({
                    where: { parentId: commentId },
                }),
                // 4. Finally delete the comment itself
                this.prisma.comment.delete({
                    where: { id: commentId },
                }),
            ]);
        }

        return {
            success: true,
            message: 'Comment deleted successfully',
        };
    }

    /**
     * Add a reply to a comment
     */
    async addReplyToComment(
        commentId: string,
        data: {
            author: string;
            content: string;
        },
    ) {
        const parentComment = await this.prisma.comment.findUnique({
            where: { id: commentId },
            select: { id: true, blogId: true },
        });

        if (!parentComment) {
            throw new NotFoundException('Comment not found');
        }

        const reply = await this.prisma.comment.create({
            data: {
                blogId: parentComment.blogId,
                parentId: commentId,
                author: data.author,
                content: data.content,
            },
            select: {
                id: true,
                author: true,
                content: true,
                likes: true,
                createdAt: true,
            },
        });

        return {
            success: true,
            message: 'Reply added successfully',
            data: reply,
        };
    }

    /**
     * Like or unlike a comment
     */
    async toggleCommentLike(
        commentId: string,
        userId: string, // IP address or user identifier
    ) {
        const comment = await this.prisma.comment.findUnique({
            where: { id: commentId },
            select: { id: true, likes: true },
        });

        if (!comment) {
            throw new NotFoundException('Comment not found');
        }

        // Check if user has already liked this comment
        const existingLike = await this.prisma.commentLike.findUnique({
            where: {
                commentId_userId: {
                    commentId,
                    userId,
                },
            },
        });

        if (existingLike) {
            // Unlike: remove the like and decrement counter
            await this.prisma.$transaction([
                this.prisma.commentLike.delete({
                    where: { id: existingLike.id },
                }),
                this.prisma.comment.update({
                    where: { id: commentId },
                    data: { likes: { decrement: 1 } },
                }),
            ]);

            return {
                success: true,
                message: 'Comment unliked',
                liked: false,
                likes: comment.likes - 1,
            };
        } else {
            // Like: create like record and increment counter
            await this.prisma.$transaction([
                this.prisma.commentLike.create({
                    data: {
                        commentId,
                        userId,
                    },
                }),
                this.prisma.comment.update({
                    where: { id: commentId },
                    data: { likes: { increment: 1 } },
                }),
            ]);

            return {
                success: true,
                message: 'Comment liked',
                liked: true,
                likes: comment.likes + 1,
            };
        }
    }
}
