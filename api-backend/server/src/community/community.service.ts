import { Injectable, NotFoundException, BadRequestException, HttpException, HttpStatus } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { OpenRouterService } from '../ai/services/openrouter.service';

const hubToDbCategories: Record<string, string[]> = {
  eligibility: ['Education Loans'],
  loan: ['Education Loans'],
  'education loans': ['Education Loans'],
  universities: ['Universities'],
  courses: ['Courses'],
  scholarships: ['Scholarship'],
  scholarship: ['Scholarship'],
  visa: ['Visa & Immigration'],
  'visa & immigration': ['Visa & Immigration'],
  accommodation: ['Accommodation'],
  gre: ['GRE / GMAT', 'IELTS / TOEFL', 'Exams'],
  'gre / gmat': ['GRE / GMAT', 'IELTS / TOEFL', 'Exams'],
  'ielts / toefl': ['GRE / GMAT', 'IELTS / TOEFL', 'Exams'],
  exams: ['GRE / GMAT', 'IELTS / TOEFL', 'Exams'],
  jobs: ['Career & Jobs'],
  'career & jobs': ['Career & Jobs'],
  general: ['General'],
};

export function resolveCategories(category?: string): string[] | null {
  if (!category) return null;
  const catKey = category.toLowerCase().trim();
  return hubToDbCategories[catKey] || [category];
}

@Injectable()
export class CommunityService {
  private get db() {
    return this.supabase.getClient();
  }

  private otpStore = new Map<string, { otp: string; expiresAt: Date }>();

  constructor(
    private supabase: SupabaseService,
    private openRouterService: OpenRouterService,
  ) {}

  // ==================== MENTORSHIP METHODS ====================

  async getAllMentors(filters: any) {
    const { university, country, loanType, category, limit, offset } = filters;

    let query = this.db
      .from('Mentor')
      .select('*', { count: 'exact' })
      .eq('isActive', true)
      .eq('isApproved', true)
      .order('rating', { ascending: false })
      .order('studentsMentored', { ascending: false });

    if (university) query = query.ilike('university', `%${university}%`);
    if (country) query = query.ilike('country', `%${country}%`);
    if (loanType) query = query.ilike('loanType', `%${loanType}%`);
    if (category) {
      const resolved = resolveCategories(category);
      if (resolved) {
        query = query.in('category', resolved);
      }
    }
    if (limit) query = query.limit(limit);
    if (offset) query = query.range(offset, offset + (limit || 20) - 1);

    const { data: mentors, count } = await query;
    return { success: true, data: mentors || [], pagination: { total: count || 0, limit, offset, hasMore: (offset || 0) + (mentors?.length || 0) < (count || 0) } };
  }

  async getFeaturedMentors(limit: number) {
    const { data } = await this.db.from('Mentor').select('*').eq('isActive', true).eq('isApproved', true).gte('rating', 4.5).order('rating', { ascending: false }).order('studentsMentored', { ascending: false }).limit(limit);
    return { success: true, data: data || [] };
  }

  async getMentorById(id: string) {
    const { data: mentor } = await this.db.from('Mentor').select('*').eq('id', id).single();
    if (!mentor) throw new NotFoundException('Mentor not found');
    return { success: true, data: mentor };
  }

  async bookMentorSession(mentorId: string, bookingData: any) {
    const { data: mentor } = await this.db.from('Mentor').select('id, isActive').eq('id', mentorId).single();
    if (!mentor) throw new NotFoundException('Mentor not found');
    if (!mentor.isActive) throw new BadRequestException('Mentor is not currently accepting bookings');

    const { data: booking, error } = await this.db.from('MentorBooking').insert({ mentorId, ...bookingData, status: 'pending' }).select().single();
    if (error) throw error;
    return { success: true, message: 'Booking request submitted successfully', data: booking };
  }

  async applyAsMentor(applicationData: any) {
    if (!applicationData?.email) throw new BadRequestException('Email is required');
    if (!applicationData.name) throw new BadRequestException('Name is required');
    if (!applicationData.university) throw new BadRequestException('University is required');
    if (!applicationData.country) throw new BadRequestException('Country is required');

    const { data: existing } = await this.db.from('Mentor').select('id').eq('email', applicationData.email).single();
    if (existing) throw new BadRequestException('A mentor with this email already exists');

    const { data: mentor, error } = await this.db.from('Mentor').insert({
      name: applicationData.name, email: applicationData.email, phone: applicationData.phone || null,
      university: applicationData.university, degree: applicationData.degree || '', country: applicationData.country,
      loanBank: applicationData.loanBank || '', loanAmount: applicationData.loanAmount || '',
      interestRate: applicationData.interestRate || null, loanType: applicationData.loanType || null,
      category: applicationData.category || null, bio: applicationData.bio || '',
      expertise: applicationData.expertise || [], linkedIn: applicationData.linkedIn || null,
      image: applicationData.image || null, isActive: false, isApproved: false, rating: 0, studentsMentored: 0,
    }).select().single();
    if (error) throw error;
    return { success: true, message: 'Mentor application submitted successfully. We will review and get back to you soon.', data: mentor };
  }

  async getMentorStats() {
    const [{ count: total }, { count: active }, { data: mentors }] = await Promise.all([
      this.db.from('Mentor').select('*', { count: 'exact', head: true }).eq('isApproved', true),
      this.db.from('Mentor').select('*', { count: 'exact', head: true }).eq('isActive', true).eq('isApproved', true),
      this.db.from('Mentor').select('rating, studentsMentored').eq('isApproved', true),
    ]);

    const avgRating = mentors?.length ? mentors.reduce((s: number, m: any) => s + (m.rating || 0), 0) / mentors.length : 0;
    const totalMentored = mentors?.reduce((s: number, m: any) => s + (m.studentsMentored || 0), 0) || 0;

    return { success: true, data: { totalMentors: total || 0, activeMentors: active || 0, averageRating: avgRating, totalStudentsMentored: totalMentored } };
  }

  // ==================== EVENTS METHODS ====================

  async getAllEvents(filters: any) {
    const { type, category, featured, limit, offset } = filters;

    let query = this.db.from('CommunityEvent').select('*', { count: 'exact' }).order('date', { ascending: true });
    if (type) query = query.eq('type', type);
    if (category) query = query.eq('category', category);
    if (featured !== undefined) query = query.eq('isFeatured', featured);
    if (limit) query = query.limit(limit);
    if (offset) query = query.range(offset, offset + (limit || 20) - 1);

    const { data: events, count } = await query;
    return { success: true, data: events || [], pagination: { total: count || 0, limit, offset, hasMore: (offset || 0) + (events?.length || 0) < (count || 0) } };
  }

  async getUpcomingEvents(limit: number) {
    const { data } = await this.db.from('CommunityEvent').select('*').gte('date', new Date().toISOString()).order('date', { ascending: true }).limit(limit);
    return { success: true, data: data || [] };
  }

  async getPastEvents(limit: number, offset: number) {
    const { data, count } = await this.db.from('CommunityEvent').select('*', { count: 'exact' }).lt('date', new Date().toISOString()).order('date', { ascending: false }).range(offset, offset + limit - 1);
    return { success: true, data: data || [], pagination: { total: count || 0, limit, offset, hasMore: offset + (data?.length || 0) < (count || 0) } };
  }

  async getEventById(id: string) {
    const { data: event } = await this.db.from('CommunityEvent').select('*').eq('id', id).single();
    if (!event) throw new NotFoundException('Event not found');
    const { count: registeredCount } = await this.db.from('EventRegistration').select('*', { count: 'exact', head: true }).eq('eventId', id);
    return { success: true, data: { ...event, registeredCount: registeredCount || 0 } };
  }

  async registerForEvent(eventId: string, registrationData: any) {
    const { data: event } = await this.db.from('CommunityEvent').select('*').eq('id', eventId).single();
    if (!event) throw new NotFoundException('Event not found');
    if (new Date(event.date) < new Date()) throw new BadRequestException('Cannot register for past events');

    const { count: registeredCount } = await this.db.from('EventRegistration').select('*', { count: 'exact', head: true }).eq('eventId', eventId);
    if (event.maxAttendees && (registeredCount || 0) >= event.maxAttendees) throw new BadRequestException('Event is full');

    const { data: existingReg } = await this.db.from('EventRegistration').select('id').eq('eventId', eventId).eq('email', registrationData.email).single();
    if (existingReg) throw new BadRequestException('You are already registered for this event');

    const { data: registration, error } = await this.db.from('EventRegistration').insert({ eventId, ...registrationData }).select().single();
    if (error) throw error;

    await this.db.from('CommunityEvent').update({ attendeesCount: (event.attendeesCount || 0) + 1 }).eq('id', eventId);
    return { success: true, message: 'Successfully registered for the event', data: registration };
  }

  // ==================== SUCCESS STORIES METHODS ====================

  async getAllStories(filters: any) {
    const { country, category, limit, offset } = filters;

    let query = this.db.from('SuccessStory').select('*', { count: 'exact' }).eq('isApproved', true).order('createdAt', { ascending: false });
    if (country) query = query.ilike('country', `%${country}%`);
    if (category) {
      const resolved = resolveCategories(category);
      if (resolved) {
        query = query.in('category', resolved);
      }
    }
    if (limit) query = query.limit(limit);
    if (offset) query = query.range(offset, offset + (limit || 20) - 1);

    const { data: stories, count } = await query;
    return { success: true, data: stories || [], pagination: { total: count || 0, limit, offset, hasMore: (offset || 0) + (stories?.length || 0) < (count || 0) } };
  }

  async getFeaturedStories(limit: number) {
    const { data } = await this.db.from('SuccessStory').select('*').eq('isApproved', true).eq('isFeatured', true).order('createdAt', { ascending: false }).limit(limit);
    return { success: true, data: data || [] };
  }

  async getStoryById(id: string) {
    const { data: story } = await this.db.from('SuccessStory').select('*').eq('id', id).single();
    if (!story) throw new NotFoundException('Story not found');
    return { success: true, data: story };
  }

  async submitStory(storyData: any) {
    const { data: story, error } = await this.db.from('SuccessStory').insert({ ...storyData, isApproved: false, isFeatured: false }).select().single();
    if (error) throw error;
    return { success: true, message: 'Success story submitted successfully. We will review and publish it soon.', data: story };
  }

  // ==================== RESOURCES METHODS ====================

  async getAllResources(filters: any) {
    const { type, category, limit, offset } = filters;

    let query = this.db.from('CommunityResource').select('*', { count: 'exact' }).order('createdAt', { ascending: false });
    if (type) query = query.eq('type', type);
    if (category) {
      const resolved = resolveCategories(category);
      if (resolved) {
        query = query.in('category', resolved);
      }
    }
    if (limit) query = query.limit(limit);
    if (offset) query = query.range(offset, offset + (limit || 20) - 1);

    const { data: resources, count } = await query;
    return { success: true, data: resources || [], pagination: { total: count || 0, limit, offset, hasMore: (offset || 0) + (resources?.length || 0) < (count || 0) } };
  }

  async getPopularResources(limit: number) {
    const { data } = await this.db.from('CommunityResource').select('*').order('downloads', { ascending: false }).limit(limit);
    return { success: true, data: data || [] };
  }

  async getResourceById(id: string) {
    const { data: resource } = await this.db.from('CommunityResource').select('*').eq('id', id).single();
    if (!resource) throw new NotFoundException('Resource not found');
    return { success: true, data: resource };
  }

  async trackResourceView(resourceId: string) {
    const { data: resource } = await this.db.from('CommunityResource').select('downloads').eq('id', resourceId).single();
    const { data: updated } = await this.db.from('CommunityResource').update({ downloads: (resource?.downloads || 0) + 1 }).eq('id', resourceId).select('downloads').single();
    return { success: true, data: { downloads: updated?.downloads } };
  }

  // ==================== ADMIN METHODS ====================

  async createMentor(mentorData: any) {
    const { data: mentor, error } = await this.db.from('Mentor').insert({ ...mentorData, expertise: mentorData.expertise || [], isActive: mentorData.isActive !== undefined ? mentorData.isActive : true, isApproved: true, rating: mentorData.rating || 0, studentsMentored: mentorData.studentsMentored || 0 }).select().single();
    if (error) throw error;
    return { success: true, message: 'Mentor created successfully', data: mentor };
  }

  async updateMentor(id: string, updateData: any) {
    const { data: mentor, error } = await this.db.from('Mentor').update(updateData).eq('id', id).select().single();
    if (error) throw error;
    return { success: true, message: 'Mentor updated successfully', data: mentor };
  }

  async deleteMentor(id: string) {
    await this.db.from('Mentor').delete().eq('id', id);
    return { success: true, message: 'Mentor deleted successfully' };
  }

  async createEvent(eventData: any) {
    const { data: event, error } = await this.db.from('CommunityEvent').insert({ ...eventData, attendeesCount: 0, isFeatured: eventData.isFeatured || false }).select().single();
    if (error) throw error;
    return { success: true, message: 'Event created successfully', data: event };
  }

  async updateEvent(id: string, updateData: any) {
    const { data: event, error } = await this.db.from('CommunityEvent').update(updateData).eq('id', id).select().single();
    if (error) throw error;
    return { success: true, message: 'Event updated successfully', data: event };
  }

  async deleteEvent(id: string) {
    await this.db.from('CommunityEvent').delete().eq('id', id);
    return { success: true, message: 'Event deleted successfully' };
  }

  async createResource(resourceData: any) {
    const { data: resource, error } = await this.db.from('CommunityResource').insert({ ...resourceData, downloads: 0, isFeatured: resourceData.isFeatured || false }).select().single();
    if (error) throw error;
    return { success: true, message: 'Resource created successfully', data: resource };
  }

  async updateResource(id: string, updateData: any) {
    const { data: resource, error } = await this.db.from('CommunityResource').update(updateData).eq('id', id).select().single();
    if (error) throw error;
    return { success: true, message: 'Resource updated successfully', data: resource };
  }

  async deleteResource(id: string) {
    await this.db.from('CommunityResource').delete().eq('id', id);
    return { success: true, message: 'Resource deleted successfully' };
  }

  async createStory(storyData: any) {
    const { data: story, error } = await this.db.from('SuccessStory').insert({ ...storyData, isApproved: storyData.isApproved !== undefined ? storyData.isApproved : true, isFeatured: storyData.isFeatured || false }).select().single();
    if (error) throw error;
    return { success: true, message: 'Success story created successfully', data: story };
  }

  async updateStory(id: string, updateData: any) {
    const { data: story, error } = await this.db.from('SuccessStory').update(updateData).eq('id', id).select().single();
    if (error) throw error;
    return { success: true, message: 'Success story updated successfully', data: story };
  }

  async deleteStory(id: string) {
    await this.db.from('SuccessStory').delete().eq('id', id);
    return { success: true, message: 'Success story deleted successfully' };
  }

  async approveMentor(id: string, approved: boolean, reason?: string) {
    const { data: mentor, error } = await this.db.from('Mentor').update({ isApproved: approved, isActive: approved, rejectionReason: approved ? null : reason }).eq('id', id).select().single();
    if (error) throw error;
    return { success: true, message: approved ? 'Mentor approved' : 'Mentor rejected', data: mentor };
  }

  async approveStory(id: string, approved: boolean, reason?: string) {
    const { data: story, error } = await this.db.from('SuccessStory').update({ isApproved: approved, rejectionReason: approved ? null : reason }).eq('id', id).select().single();
    if (error) throw error;
    return { success: true, message: approved ? 'Story approved' : 'Story rejected', data: story };
  }

  async getAllBookings(filters: any) {
    const { status, mentorId, limit, offset } = filters;

    let query = this.db.from('MentorBooking').select('*, mentor:Mentor!mentorId(name, email, university)', { count: 'exact' }).order('createdAt', { ascending: false });
    if (status) query = query.eq('status', status);
    if (mentorId) query = query.eq('mentorId', mentorId);
    if (limit) query = query.limit(limit);
    if (offset) query = query.range(offset, offset + (limit || 20) - 1);

    const { data: bookings, count } = await query;
    return { success: true, data: bookings || [], pagination: { total: count || 0, limit, offset, hasMore: (offset || 0) + (bookings?.length || 0) < (count || 0) } };
  }

  async getAllRegistrations(filters: any) {
    const { eventId, limit, offset } = filters;

    let query = this.db.from('EventRegistration').select('*, event:CommunityEvent!eventId(title, date, type)', { count: 'exact' }).order('createdAt', { ascending: false });
    if (eventId) query = query.eq('eventId', eventId);
    if (limit) query = query.limit(limit);
    if (offset) query = query.range(offset, offset + (limit || 20) - 1);

    const { data: registrations, count } = await query;
    return { success: true, data: registrations || [], pagination: { total: count || 0, limit, offset, hasMore: (offset || 0) + (registrations?.length || 0) < (count || 0) } };
  }

  async getCommunityStats() {
    const [
      { count: mentorCount },
      { count: eventCount },
      { count: storyCount },
      { count: resourceCount },
      { count: bookingCount },
      { count: registrationCount },
      { count: forumPostCount },
    ] = await Promise.all([
      this.db.from('Mentor').select('*', { count: 'exact', head: true }).eq('isApproved', true),
      this.db.from('CommunityEvent').select('*', { count: 'exact', head: true }),
      this.db.from('SuccessStory').select('*', { count: 'exact', head: true }).eq('isApproved', true),
      this.db.from('CommunityResource').select('*', { count: 'exact', head: true }),
      this.db.from('MentorBooking').select('*', { count: 'exact', head: true }),
      this.db.from('EventRegistration').select('*', { count: 'exact', head: true }),
      this.db.from('ForumPost').select('*', { count: 'exact', head: true }),
    ]);

    return { success: true, data: { mentors: mentorCount || 0, events: eventCount || 0, stories: storyCount || 0, resources: resourceCount || 0, bookings: bookingCount || 0, registrations: registrationCount || 0, forumPosts: forumPostCount || 0 } };
  }

  // ==================== FORUM/TOPIC METHODS ====================

  async getForumPosts(filters: any, userId?: string) {
    const { category, tag, limit, offset, sort } = filters;

    let query = this.db
      .from('ForumPost')
      .select('*, author:User!authorId(firstName, lastName, role), commentCount:ForumComment(count)', { count: 'exact' })
      .order(sort === 'popular' ? 'likes' : 'createdAt', { ascending: false });

    if (category) {
      const resolved = resolveCategories(category);
      if (resolved) {
        query = query.in('category', resolved);
      }
    }
    if (tag) query = query.contains('tags', [tag]);
    if (limit) query = query.limit(limit);
    if (offset) query = query.range(offset, offset + (limit || 20) - 1);

    const { data: posts, count } = await query;

    // Check which posts are liked by the userId
    let likedPostIds = new Set<string>();
    if (userId && posts && posts.length > 0) {
      const { data: likedPosts } = await this.db
        .from('PostLike')
        .select('postId')
        .eq('userId', userId)
        .in('postId', posts.map((p: any) => p.id));
      likedPostIds = new Set((likedPosts || []).map((l: any) => l.postId));
    }

    return {
      success: true,
      data: (posts || []).map((post: any) => ({
        ...post,
        commentCount: Array.isArray(post.commentCount) ? (post.commentCount[0]?.count ?? 0) : (post.commentCount || 0),
        liked: likedPostIds.has(post.id),
      })),
      pagination: { total: count || 0, limit, offset, hasMore: (offset || 0) + (posts?.length || 0) < (count || 0) },
    };
  }

  async getForumPostById(id: string, userId?: string) {
    const { data: post } = await this.db
      .from('ForumPost')
      .select('*, author:User!authorId(firstName, lastName, id, role), comments:ForumComment!postId(*, author:User!authorId(firstName, lastName, id, role), replies:ForumComment!parentId(*, author:User!authorId(firstName, lastName, id, role)))')
      .eq('id', id)
      .maybeSingle();

    if (!post) throw new NotFoundException('Post not found');

    // Increment views
    this.db.from('ForumPost').update({ views: (post.views || 0) + 1 }).eq('id', id).then(() => {});

    let liked = false;
    const likedCommentIds = new Set<string>();

    if (userId) {
      const { data: postLike } = await this.db.from('PostLike').select('id').eq('postId', id).eq('userId', userId).maybeSingle();
      liked = !!postLike;

      const allCommentIds: string[] = [];
      (post.comments || []).forEach((c: any) => {
        allCommentIds.push(c.id);
        (c.replies || []).forEach((r: any) => allCommentIds.push(r.id));
      });

      if (allCommentIds.length > 0) {
        const { data: commentLikes } = await this.db.from('ForumCommentLike').select('commentId').eq('userId', userId).in('commentId', allCommentIds);
        (commentLikes || []).forEach((l: any) => likedCommentIds.add(l.commentId));
      }
    }

    const topLevelComments = (post.comments || []).filter((c: any) => !c.parentId);
    const commentsWithLikes = topLevelComments.map((c: any) => ({
      ...c,
      liked: likedCommentIds.has(c.id),
      replies: (c.replies || []).map((r: any) => ({ ...r, liked: likedCommentIds.has(r.id) })),
    }));

    return { success: true, data: { ...post, comments: commentsWithLikes, commentCount: (post.comments || []).length, liked } };
  }

  async searchSimilarPosts(query: string) {
    if (!query || query.trim().length < 3) return { success: true, data: [] };

    const stopwords = new Set(['the', 'and', 'for', 'how', 'can', 'what', 'why', 'which', 'does', 'are', 'was', 'get', 'not', 'any', 'but', 'you', 'your', 'that', 'this', 'have', 'with', 'will', 'from', 'its', 'into', 'than', 'then', 'about']);
    const keywords = query.trim().toLowerCase().split(/\s+/).filter((w) => w.length >= 3 && !stopwords.has(w));
    if (keywords.length === 0) return { success: true, data: [] };

    // Search posts matching any keyword
    const { data: posts } = await this.db
      .from('ForumPost')
      .select('id, title, category, createdAt, comments:ForumComment(count)')
      .or(keywords.map((kw) => `title.ilike.%${kw}%`).join(','))
      .order('createdAt', { ascending: false })
      .limit(20);

    const scored = (posts || []).map((p: any) => {
      const t = (p.title || '').toLowerCase();
      const score = keywords.reduce((acc: number, kw: string) => acc + (t.includes(kw) ? 1 : 0), 0);
      return { ...p, score };
    });

    scored.sort((a, b) => b.score - a.score);
    const top5 = scored.slice(0, 5).map(({ score, ...p }: any) => ({
      ...p,
      commentCount: Array.isArray(p.comments) ? (p.comments[0]?.count ?? 0) : 0,
    }));

    return { success: true, data: top5 };
  }

  async getHubs() {
    const hubs = [
      {
        id: 'General',
        title: 'General',
        description: 'General discussions, questions, and general student lounge.',
        icon: 'chat',
        stats: { members: 1250, discussions: 340 }
      },
      {
        id: 'Education Loans',
        title: 'Education Loans',
        description: 'Sanction process, interest rates, collateral vs non-collateral loans, and bank comparison.',
        icon: 'account_balance',
        stats: { members: 890, discussions: 215 }
      },
      {
        id: 'Universities',
        title: 'Universities',
        description: 'University selection, admit updates, course reviews, and campus life.',
        icon: 'school',
        stats: { members: 950, discussions: 180 }
      },
      {
        id: 'Courses & Programs',
        title: 'Courses & Programs',
        description: 'STEM designations, course curriculum, prerequisites, and specialization choices.',
        icon: 'book',
        stats: { members: 620, discussions: 110 }
      },
      {
        id: 'Exams & Test Prep',
        title: 'Exams & Test Prep',
        description: 'Preparation strategies, test dates, score reporting, and resources for GRE, GMAT, IELTS, TOEFL.',
        icon: 'quiz',
        stats: { members: 780, discussions: 145 }
      },
      {
        id: 'GRE / GMAT',
        title: 'GRE / GMAT',
        description: 'GRE/GMAT study plans, practice tests, score targets, and university score requirements.',
        icon: 'analytics',
        stats: { members: 540, discussions: 95 }
      },
      {
        id: 'IELTS / TOEFL',
        title: 'IELTS / TOEFL',
        description: 'English proficiency test tips, speaking evaluation, band score requirements.',
        icon: 'translate',
        stats: { members: 610, discussions: 105 }
      },
      {
        id: 'Scholarships',
        title: 'Scholarships',
        description: 'Merit-based scholarships, financial aid, teaching assistantships (TA/RA), and grants.',
        icon: 'card_membership',
        stats: { members: 810, discussions: 160 }
      },
      {
        id: 'Visa & Immigration',
        title: 'Visa & Immigration',
        description: 'F-1 / UKVI visa slot booking, DS-160 filling, mock interviews, and consulate updates.',
        icon: 'flight_takeoff',
        stats: { members: 1120, discussions: 290 }
      },
      {
        id: 'Career & Jobs',
        title: 'Career & Jobs',
        description: 'OPT / CPT work authorization, internship hunting, networking, and post-grad job search.',
        icon: 'work',
        stats: { members: 730, discussions: 130 }
      }
    ];

    return { success: true, data: hubs };
  }

  async createForumPost(userId: string, data: any) {
    const { data: user } = await this.db.from('User').select('id').eq('id', userId).maybeSingle();
    if (!user) throw new NotFoundException('User not found');

    // AI content relevance and quality verification check
    const verification = await this.validateCommunityPostContent(
      data.title || '',
      data.content || '',
      data.category || 'General'
    );

    if (!verification.isAllowed) {
      throw new BadRequestException(`CONTENT_NOT_RELEVANT: ${verification.reason}`);
    }

    // Idempotency check
    const sixtySecondsAgo = new Date(Date.now() - 60000).toISOString();
    const { data: recentPost } = await this.db
      .from('ForumPost')
      .select('*')
      .eq('authorId', userId)
      .eq('title', data.title)
      .gte('createdAt', sixtySecondsAgo)
      .maybeSingle();

    if (recentPost && data.force !== true) {
      return { success: true, message: 'Post already created recently', data: recentPost, isDuplicate: true };
    }

    const resolved = resolveCategories(data.category);
    const canonicalCategory = (resolved && resolved.length > 0) ? resolved[0] : (data.category || 'General');

    const { data: post, error } = await this.db
      .from('ForumPost')
      .insert({ title: data.title, content: data.content, category: canonicalCategory, tags: data.tags || [], authorId: userId, isMentorOnly: data.isMentorOnly || false, updatedAt: new Date().toISOString() })
      .select('*, author:User!authorId(firstName, lastName, role, id)')
      .maybeSingle();

    if (error) {
      console.error('[CommunityService] error inserting ForumPost:', error);
      throw new BadRequestException('Failed to create post: ' + error.message);
    }
    return { success: true, message: 'Post created successfully', data: post };
  }

  async createForumComment(userId: string, postId: string, content: string, parentId?: string) {
    const tenSecondsAgo = new Date(Date.now() - 10000).toISOString();
    const { data: recentComment } = await this.db.from('ForumComment').select('*').eq('authorId', userId).eq('postId', postId).eq('content', content).gte('createdAt', tenSecondsAgo).maybeSingle();
    if (recentComment) return { success: true, data: recentComment };

    const { data: post } = await this.db.from('ForumPost').select('id').eq('id', postId).maybeSingle();
    if (!post) throw new NotFoundException('Post not found');

    const { data: comment, error } = await this.db.from('ForumComment').insert({ content, postId, authorId: userId, parentId: parentId || null, updatedAt: new Date().toISOString() }).select('*, author:User!authorId(firstName, lastName, role)').single();
    if (error) throw error;
    return { success: true, message: 'Comment added successfully', data: comment };
  }

  async likeForumComment(userId: string, id: string) {
    try {
      const { data: existing } = await this.db.from('ForumCommentLike').select('id').eq('commentId', id).eq('userId', userId).maybeSingle();
      const { data: comment } = await this.db.from('ForumComment').select('likes').eq('id', id).maybeSingle();
      const currentLikes = comment?.likes || 0;

      if (existing) {
        await this.db.from('ForumCommentLike').delete().eq('id', existing.id);
        await this.db.from('ForumComment').update({ likes: Math.max(0, currentLikes - 1) }).eq('id', id);
        const { data: updated } = await this.db.from('ForumComment').select('likes').eq('id', id).maybeSingle();
        return { success: true, likes: updated?.likes || 0, liked: false };
      } else {
        await this.db.from('ForumCommentLike').insert({ commentId: id, userId });
        await this.db.from('ForumComment').update({ likes: currentLikes + 1 }).eq('id', id);
        const { data: updated } = await this.db.from('ForumComment').select('likes').eq('id', id).maybeSingle();
        return { success: true, likes: updated?.likes || 0, liked: true };
      }
    } catch (error) {
      console.error('[CommunityService] likeForumComment failed:', error);
      throw new BadRequestException('Failed to process like action on comment');
    }
  }

  async likeForumPost(userId: string, id: string) {
    try {
      const { data: existing } = await this.db.from('PostLike').select('id').eq('postId', id).eq('userId', userId).maybeSingle();
      const { data: post } = await this.db.from('ForumPost').select('likes').eq('id', id).maybeSingle();
      const currentLikes = post?.likes || 0;

      if (existing) {
        await this.db.from('PostLike').delete().eq('id', existing.id);
        await this.db.from('ForumPost').update({ likes: Math.max(0, currentLikes - 1) }).eq('id', id);
        const { data: updated } = await this.db.from('ForumPost').select('likes').eq('id', id).maybeSingle();
        return { success: true, likes: updated?.likes || 0, liked: false };
      } else {
        await this.db.from('PostLike').insert({ postId: id, userId });
        await this.db.from('ForumPost').update({ likes: currentLikes + 1 }).eq('id', id);
        const { data: updated } = await this.db.from('ForumPost').select('likes').eq('id', id).maybeSingle();
        return { success: true, likes: updated?.likes || 0, liked: true };
      }
    } catch (error) {
      console.error('[CommunityService] likeForumPost failed:', error);
      throw new BadRequestException('Failed to process like action on post');
    }
  }

  async shareForumPost(id: string) {
    try {
      const { data: post } = await this.db.from('ForumPost').select('views').eq('id', id).single();
      await this.db.from('ForumPost').update({ views: (post?.views || 0) + 1 }).eq('id', id);
      return { success: true, message: 'Post shared' };
    } catch (error) {
      throw new NotFoundException('Post not found');
    }
  }

  async deleteForumPost(id: string) {
    try {
      await this.db.from('ForumPost').delete().eq('id', id);
      return { success: true, message: 'Post deleted successfully' };
    } catch (error) {
      throw new NotFoundException('Post not found');
    }
  }

  async deleteForumComment(userId: string, userRole: string, commentId: string) {
    const { data: comment } = await this.db.from('ForumComment').select('id, authorId').eq('id', commentId).single();
    if (!comment) throw new NotFoundException('Comment not found');
    if (comment.authorId !== userId && userRole !== 'admin') throw new HttpException('You can only delete your own comments', HttpStatus.FORBIDDEN);
    await this.db.from('ForumComment').delete().eq('id', commentId);
    return { success: true, message: 'Comment deleted successfully' };
  }

  // ==================== MENTOR AUTH & DASHBOARD METHODS ====================

  async requestMentorOTP(email: string) {
    const { data: mentor } = await this.db.from('Mentor').select('*').eq('email', email).single();
    if (!mentor) throw new NotFoundException('Mentor not found with this email');
    if (!mentor.isApproved) throw new BadRequestException('Your mentor application is pending approval');
    if (!mentor.isActive) throw new BadRequestException('Your mentor account is not active');

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);
    this.otpStore.set(email, { otp, expiresAt });

    console.log(`\n🔐 OTP for ${email}: ${otp}\n`);
    return { success: true, message: 'OTP sent to your email. Please check your inbox.', data: { email, expiresIn: 300, ...(process.env.NODE_ENV === 'development' ? { otp } : {}) } };
  }

  async verifyMentorOTP(email: string, otp: string) {
    const { data: mentor } = await this.db.from('Mentor').select('*').eq('email', email).single();
    if (!mentor) throw new NotFoundException('Mentor not found');

    const storedOTP = this.otpStore.get(email);
    if (!storedOTP) throw new BadRequestException('OTP not found. Please request a new OTP.');
    if (new Date() > storedOTP.expiresAt) { this.otpStore.delete(email); throw new BadRequestException('OTP has expired. Please request a new OTP.'); }
    if (storedOTP.otp !== otp) throw new BadRequestException('Invalid OTP. Please try again.');

    this.otpStore.delete(email);
    return { success: true, message: 'Login successful', data: { id: mentor.id, name: mentor.name, email: mentor.email, university: mentor.university, isApproved: mentor.isApproved, isActive: mentor.isActive } };
  }

  async getMentorProfile(mentorId: string) {
    const { data: mentor } = await this.db.from('Mentor').select('*').eq('id', mentorId).single();
    if (!mentor) throw new NotFoundException('Mentor not found');

    const { data: bookings } = await this.db.from('MentorBooking').select('status').eq('mentorId', mentorId);
    const stats = { total: 0, pending: 0, approved: 0, rejected: 0, completed: 0 };
    (bookings || []).forEach((b: any) => { stats.total++; if (stats[b.status] !== undefined) stats[b.status]++; });

    return { success: true, data: { mentor, stats } };
  }

  async getMentorBookings(mentorId: string, filters: any) {
    const { status, limit, offset } = filters;

    let query = this.db.from('MentorBooking').select('*', { count: 'exact' }).eq('mentorId', mentorId).order('createdAt', { ascending: false });
    if (status) query = query.eq('status', status);
    if (limit) query = query.limit(limit || 20);
    if (offset) query = query.range(offset || 0, (offset || 0) + (limit || 20) - 1);

    const { data: bookings, count } = await query;
    return { success: true, data: bookings || [], pagination: { total: count || 0, limit: limit || 20, offset: offset || 0, hasMore: (offset || 0) + (bookings?.length || 0) < (count || 0) } };
  }

  async updateBookingStatus(mentorId: string, bookingId: string, status: string) {
    const { data: booking } = await this.db.from('MentorBooking').select('id').eq('id', bookingId).eq('mentorId', mentorId).single();
    if (!booking) throw new NotFoundException('Booking not found or not authorized');

    const { data: updatedBooking, error } = await this.db.from('MentorBooking').update({ status }).eq('id', bookingId).select().single();
    if (error) throw error;
    return { success: true, message: `Booking ${status} successfully`, data: updatedBooking };
  }

  async updateMentorProfile(mentorId: string, updateData: any) {
    const allowedFields = ['phone', 'bio', 'expertise', 'linkedIn', 'image', 'isActive'];
    const dataToUpdate: any = {};
    Object.keys(updateData).forEach((key) => { if (allowedFields.includes(key)) dataToUpdate[key] = updateData[key]; });

    const { data: mentor, error } = await this.db.from('Mentor').update(dataToUpdate).eq('id', mentorId).select().single();
    if (error) throw error;
    return { success: true, message: 'Profile updated successfully', data: mentor };
  }

  async getAllForumPostsAdmin(filters: any) {
    const { category, limit, offset, sort } = filters;

    let query = this.db
      .from('ForumPost')
      .select('*, author:User!authorId(firstName, lastName, role, email), comments:ForumComment(count)', { count: 'exact' })
      .order('isPinned', { ascending: false })
      .order(sort === 'popular' ? 'likes' : 'createdAt', { ascending: false });

    if (category) {
      const resolved = resolveCategories(category);
      if (resolved) {
        query = query.in('category', resolved);
      }
    }
    if (limit) query = query.limit(limit);
    if (offset) query = query.range(offset, offset + (limit || 20) - 1);

    const { data: posts, count } = await query;
    return {
      success: true,
      data: (posts || []).map((p: any) => ({ ...p, commentCount: Array.isArray(p.comments) ? (p.comments[0]?.count ?? 0) : 0 })),
      pagination: { total: count || 0, limit, offset, hasMore: (offset || 0) + (posts?.length || 0) < (count || 0) },
    };
  }

  async togglePinForumPost(id: string, isPinned: boolean) {
    try {
      const { data: post, error } = await this.db.from('ForumPost').update({ isPinned }).eq('id', id).select().single();
      if (error) throw error;
      return { success: true, message: isPinned ? 'Post pinned successfully' : 'Post unpinned successfully', data: post };
    } catch (error) {
      throw new NotFoundException('Post not found');
    }
  }

  // ==================== AI DUPLICATE QUESTION DETECTION ====================

  async checkDuplicateQuestion(questionData: { title: string; content: string; category: string }) {
    try {
      // Exact match check
      const { data: exactMatch } = await this.db
        .from('ForumPost')
        .select('id, title, createdAt, comments:ForumComment(count)')
        .ilike('title', questionData.title.trim())
        .eq('category', questionData.category)
        .single();

      if (exactMatch) {
        return { isDuplicate: true, similarQuestions: [{ id: exactMatch.id, title: exactMatch.title, similarity: 1.0, reason: 'Exact title match found in this category.', url: `/community/discussions/${exactMatch.id}` }], message: 'A question with this exact title already exists.' };
      }

      const stopwords = new Set(['the', 'and', 'for', 'how', 'can', 'what', 'why', 'which', 'does', 'are', 'was', 'get', 'not', 'any', 'but', 'you', 'your', 'that', 'this', 'have', 'with', 'will', 'from', 'its', 'into', 'than', 'then', 'about']);
      const keywords = questionData.title.toLowerCase().split(/\s+/).filter((w) => w.length >= 3 && !stopwords.has(w));

      let existingQuestions: any[] = [];
      if (keywords.length > 0) {
        const resolved = resolveCategories(questionData.category) || [questionData.category];
        const { data } = await this.db
          .from('ForumPost')
          .select('id, title, content, createdAt')
          .in('category', resolved)
          .or(keywords.map((kw) => `title.ilike.%${kw}%`).join(','))
          .order('createdAt', { ascending: false })
          .limit(50);
        existingQuestions = data || [];
      }

      if (existingQuestions.length === 0) {
        const resolved = resolveCategories(questionData.category) || [questionData.category];
        const { data } = await this.db.from('ForumPost').select('id, title, content, createdAt').in('category', resolved).order('createdAt', { ascending: false }).limit(20);
        existingQuestions = data || [];
      }

      if (existingQuestions.length === 0) return { isDuplicate: false, similarQuestions: [], message: 'No similar questions found' };

      const existingQuestionsText = existingQuestions.map((q, i) => `${i + 1}. ID: ${q.id}\n   Title: "${q.title}"\n   Preview: ${(q.content || '').substring(0, 150)}...`).join('\n\n');

      const prompt = `You are an expert at detecting duplicate or highly similar questions in a community forum.\n\nNew Question:\nTitle: "${questionData.title}"\nContent: ${questionData.content}\n\nExisting Questions in the ${questionData.category} category:\n${existingQuestionsText}\n\nTask: Identify if the new question is substantially similar to any existing questions. Questions are considered similar if they ask for the same information, even if worded differently.\nHigh similarity (>= 0.8) means they should be merged or the user should be directed to the existing one.\n\nProvide your analysis in JSON format with the following structure:\n{\n  "matches": [\n    {\n      "id": "question_id",\n      "title": "question title",\n      "similarity": 0.0-1.0,\n      "reason": "brief explanation of why they're similar"\n    }\n  ]\n}\n\nIMPORTANT RULES:\n1. Only include questions with similarity >= 0.7\n2. Similarity of 0.9-1.0 means essentially the same question or intent\n3. Similarity of 0.7-0.8 means related topics but maybe slightly different focus\n4. Maximum 5 matches\n5. Respond ONLY with valid JSON, no markdown formatting`;

      const aiResponse = await this.openRouterService.getJson<{ matches: Array<{ id: string; title: string; similarity: number; reason: string }> }>(prompt);

      const validMatches = (aiResponse.matches || [])
        .filter((m) => m.similarity >= 0.7)
        .slice(0, 5)
        .map((m) => ({ id: m.id, title: m.title, similarity: m.similarity, reason: m.reason, url: `/community/discussions/${m.id}` }));

      return { isDuplicate: validMatches.length > 0, similarQuestions: validMatches, message: validMatches.length > 0 ? `Found ${validMatches.length} similar question(s)` : 'No similar questions found' };
    } catch (error) {
      console.error('Error in duplicate question detection:', error);
      return { isDuplicate: false, similarQuestions: [], message: 'Duplicate check unavailable, but you can still post your question', error: error.message };
    }
  }

  // ==================== AI POST RELEVANCE VALIDATION ====================

  async validateCommunityPostContent(title: string, content: string, category: string): Promise<{ isAllowed: boolean; reason?: string }> {
    try {
      const prompt = `You are an AI moderator for a study abroad and education finance community forum.
Your task is to analyze if a new question/post is relevant and appropriate for the forum.

A post is RELEVANT if:
1. It is a question or discussion related to study abroad, university admissions, courses, exams (like GRE, GMAT, IELTS, TOEFL, SAT, etc.), scholarships, student visas, immigration, abroad accommodation, student loans, or general education/career planning.
2. The content is meaningful, coherent, and written in a comprehensible language.

A post is NOT RELEVANT (should be blocked) if:
1. It is spam, advertisements, or promotional material not related to education.
2. It is gibberish, keyboard-mashing, nonsense, or random character sequences (e.g. "jdkssmsbsks mm jeke...").
3. It contains offensive, hateful, or highly inappropriate language.
4. It is entirely unrelated to education, student life, study abroad, study preparation, career planning, or student loans/visas/accommodation.

New Post details:
Category: "${category}"
Title: "${title}"
Content: "${content}"

Analyze the post. Respond ONLY with a JSON object in the following format:
{
  "isAllowed": true/false,
  "reason": "Brief explanation of why it is allowed or blocked. If blocked, state the reason clearly to the user (e.g., 'nonsense/gibberish content is not allowed', 'content must be related to study abroad or education finance')"
}`;

      const response = await this.openRouterService.getJson<{ isAllowed: boolean; reason?: string }>(prompt);
      return {
        isAllowed: response.isAllowed === true,
        reason: response.reason || 'Content is not relevant to study abroad or student loans.'
      };
    } catch (error) {
      console.error('Error in AI post validation:', error);
      return { isAllowed: true };
    }
  }

  async getHubData(hubId: string) {
    const hubsResult = await this.getHubs();
    const hub = hubsResult.data.find(h => h.id.toLowerCase() === hubId.toLowerCase()) || {
      id: hubId,
      title: hubId,
      description: `Discussions about ${hubId}`,
      icon: 'chat',
      stats: { members: 100, discussions: 15 }
    };

    return {
      success: true,
      data: { hub }
    };
  }

  // ==================== PERSON TO PERSON DIRECT CHAT (DYNAMIC DB TABLES) ====================

  private maskPhoneNumbers(text: string): string {
    if (!text) return text;
    const phoneRegex = /(?:\+?91[\s\.-]?)?(?:[0-9]{10}|[0-9]{5}[\s\.-][0-9]{5}|[0-9]{3}[\s\.-][0-9]{3}[\s\.-][0-9]{4}|[6-9][0-9]{9})/g;
    return text.replace(phoneRegex, 'XXXXXXXXXX');
  }

  // Shared global in-memory persistence for real-time 1-on-1 Direct Chats
  private static inMemoryDirectConversations: Map<string, any> = new Map();
  private static inMemoryDirectMessages: Map<string, any[]> = new Map();

  async getDirectConversations(userId: string) {
    const memConvs = Array.from(CommunityService.inMemoryDirectConversations.values()).filter(
      (c: any) => !userId || c.participant1Id === userId || c.participant2Id === userId || userId === 'user_me'
    );

    try {
      const { data: dbConvs, error } = await this.db
        .from('DirectConversation')
        .select('*')
        .or(`participant1Id.eq.${userId},participant2Id.eq.${userId}`)
        .order('lastMessageAt', { ascending: false });

      const convMap = new Map<string, any>();
      if (dbConvs && dbConvs.length > 0) {
        dbConvs.forEach((c: any) => convMap.set(c.id, c));
      }
      memConvs.forEach((c: any) => convMap.set(c.id, c));

      const formatted = Array.from(convMap.values()).map((c: any) => ({
        ...c,
        lastMessage: this.maskPhoneNumbers(c.lastMessage || ''),
      }));
      formatted.sort((a, b) => new Date(b.lastMessageAt || 0).getTime() - new Date(a.lastMessageAt || 0).getTime());

      return { success: true, data: formatted };
    } catch (e) {
      console.error('[CommunityService] getDirectConversations fallback to memory:', e);
      const formatted = memConvs.map((c: any) => ({
        ...c,
        lastMessage: this.maskPhoneNumbers(c.lastMessage || ''),
      }));
      formatted.sort((a, b) => new Date(b.lastMessageAt || 0).getTime() - new Date(a.lastMessageAt || 0).getTime());
      return { success: true, data: formatted };
    }
  }

  async getDirectMessages(conversationId: string, userId?: string) {
    const memMsgs = CommunityService.inMemoryDirectMessages.get(conversationId) || [];
    try {
      const { data: dbMsgs, error } = await this.db
        .from('DirectMessage')
        .select('*')
        .eq('conversationId', conversationId)
        .order('createdAt', { ascending: true });

      const msgMap = new Map<string, any>();
      if (dbMsgs && dbMsgs.length > 0) {
        dbMsgs.forEach((m: any) => msgMap.set(m.id || `${m.senderId}_${m.content}_${m.createdAt}`, m));
      }
      memMsgs.forEach((m: any) => msgMap.set(m.id || `${m.senderId}_${m.content || m.text}_${m.createdAt || m.timestamp}`, m));

      const formatted = Array.from(msgMap.values()).map((m: any) => {
        const rawContent = m.content || m.text || '';
        const isMe = userId ? (m.senderId === userId || m.senderId === 'user_me') : (m.isMe ?? false);
        return {
          id: m.id,
          conversationId: m.conversationId,
          senderId: m.senderId,
          senderName: m.senderName || 'Student',
          recipientId: m.recipientId,
          text: this.maskPhoneNumbers(rawContent),
          content: this.maskPhoneNumbers(rawContent),
          isRead: m.isRead ?? true,
          timestamp: m.createdAt || m.timestamp || new Date().toISOString(),
          createdAt: m.createdAt || m.timestamp || new Date().toISOString(),
          isMe: isMe,
        };
      });

      formatted.sort((a, b) => new Date(a.timestamp || 0).getTime() - new Date(b.timestamp || 0).getTime());
      return { success: true, data: formatted };
    } catch (e) {
      console.error('[CommunityService] getDirectMessages fallback to memory:', e);
      const formatted = memMsgs.map((m: any) => ({
        ...m,
        text: this.maskPhoneNumbers(m.text || m.content || ''),
        isMe: userId ? (m.senderId === userId || m.senderId === 'user_me') : (m.isMe ?? false),
      }));
      return { success: true, data: formatted };
    }
  }

  async sendDirectMessage(senderId: string, data: { peerId: string; peerName?: string; peerRole?: string; avatarLetter?: string; colorValue?: number; senderName?: string; text: string }) {
    const p1 = senderId < data.peerId ? senderId : data.peerId;
    const p2 = senderId < data.peerId ? data.peerId : senderId;
    const conversationId = `conv_${p1}_${p2}`;
    const now = new Date().toISOString();
    const maskedText = this.maskPhoneNumbers(data.text);
    const messageId = `dmsg_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;

    const newMsg = {
      id: messageId,
      conversationId,
      senderId,
      senderName: data.senderName || 'Student',
      recipientId: data.peerId,
      peerName: data.peerName || 'Student Member',
      peerRole: data.peerRole || 'Student',
      avatarLetter: data.avatarLetter || (data.peerName ? data.peerName[0] : 'S'),
      colorValue: data.colorValue || 3218322,
      content: data.text,
      text: maskedText,
      isRead: false,
      isMe: true,
      timestamp: now,
      createdAt: now,
    };

    // 1. Store in shared in-memory message list
    if (!CommunityService.inMemoryDirectMessages.has(conversationId)) {
      CommunityService.inMemoryDirectMessages.set(conversationId, []);
    }
    CommunityService.inMemoryDirectMessages.get(conversationId)!.push(newMsg);

    // 2. Update in-memory conversation
    const convObj = {
      id: conversationId,
      participant1Id: p1,
      participant2Id: p2,
      senderId,
      senderName: data.senderName || 'Student',
      peerId: data.peerId,
      peerName: data.peerName || 'Student Member',
      peerRole: data.peerRole || 'Student',
      avatarLetter: data.avatarLetter || (data.peerName ? data.peerName[0] : 'S'),
      colorValue: data.colorValue || 3218322,
      lastMessage: maskedText,
      lastMessageAt: now,
      unreadCount: 1,
    };
    CommunityService.inMemoryDirectConversations.set(conversationId, convObj);

    // 3. Try to persist to database
    try {
      const { data: existingConv } = await this.db
        .from('DirectConversation')
        .select('id')
        .eq('id', conversationId)
        .maybeSingle();

      if (!existingConv) {
        await this.db.from('DirectConversation').insert(convObj);
      } else {
        await this.db
          .from('DirectConversation')
          .update({
            lastMessage: data.text,
            lastMessageAt: now,
            unreadCount: 1,
          })
          .eq('id', conversationId);
      }

      await this.db
        .from('DirectMessage')
        .insert({
          id: messageId,
          conversationId,
          senderId,
          recipientId: data.peerId,
          content: data.text,
          isRead: false,
          createdAt: now,
        });
    } catch (e) {
      console.warn('Fallback sendDirectMessage in-memory save:', e);
    }

    return {
      success: true,
      message: 'Direct message sent successfully',
      data: newMsg,
    };
  }

  async markDirectConversationRead(conversationId: string, userId: string) {
    if (CommunityService.inMemoryDirectConversations.has(conversationId)) {
      const conv = CommunityService.inMemoryDirectConversations.get(conversationId);
      conv.unreadCount = 0;
    }

    try {
      await this.db
        .from('DirectMessage')
        .update({ isRead: true })
        .eq('conversationId', conversationId)
        .neq('senderId', userId);

      await this.db
        .from('DirectConversation')
        .update({ unreadCount: 0 })
        .eq('id', conversationId);

      return { success: true, message: 'Conversation marked as read' };
    } catch (e) {
      return { success: true };
    }
  }

  // ==================== SMART GROUP CHANNELS & REAL CHAT METHODS ====================

  private readonly initialGroupsSeed = [];

  // Shared global in-memory persistence for real-time Smart Groups & Chat Messages
  private static inMemoryGroups: Map<string, any> = new Map();
  private static inMemoryGroupMessages: Map<string, any[]> = new Map();

  private isStaticGroup(g: any): boolean {
    if (!g) return false;
    const id = String(g.id || '').toLowerCase();
    const title = String(g.title || '').toLowerCase().trim();
    const staticIds = ['usa_fall26', 'visa_docs', 'loan_squad', 'uk_europe', 'group_1', 'group_2', 'group_3', 'group_4'];
    const staticTitles = [
      'usa fall 2026 aspirants',
      'visa & documentation squad',
      'visa & documentation s...',
      'loan & financial aid squad',
      'uk & europe scholars',
    ];
    return staticIds.includes(id) || staticTitles.some(st => title.startsWith(st) || title.includes('usa fall') || title.includes('visa & documentation') || title.includes('loan & financial aid') || title.includes('uk & europe scholars'));
  }

  async getSmartGroups() {
    try {
      const { data: dbGroups, error } = await this.db
        .from('CommunityGroup')
        .select('*')
        .order('createdAt', { ascending: false });

      if (dbGroups && dbGroups.length > 0) {
        dbGroups.forEach((g: any) => {
          if (!this.isStaticGroup(g)) {
            CommunityService.inMemoryGroups.set(g.id, {
              ...g,
              adminEmail: g.createdBy || '',
              adminName: '',
            });
          }
        });
      }

      const allGroups = Array.from(CommunityService.inMemoryGroups.values())
        .filter((g: any) => !this.isStaticGroup(g));
      allGroups.sort((a, b) => new Date(b.createdAt || 0).getTime() - new Date(a.createdAt || 0).getTime());
      return { success: true, data: allGroups };
    } catch (e) {
      const allGroups = Array.from(CommunityService.inMemoryGroups.values())
        .filter((g: any) => !this.isStaticGroup(g));
      return { success: true, data: allGroups };
    }
  }

  async createSmartGroup(groupData: any) {
    const id = groupData.id || `group_${Date.now()}`;
    const newGroup = {
      id,
      title: groupData.title,
      subtitle: groupData.subtitle || 'Student discussion group',
      members: groupData.members || 1,
      online: groupData.online || 1,
      iconName: groupData.iconName || 'school_rounded',
      colorHex: groupData.colorHex || '#311B92',
      badge: groupData.badge || 'Custom Group',
      lastMsg: groupData.lastMsg || 'Group channel created just now!',
      adminEmail: groupData.adminEmail || '',
      adminName: groupData.adminName || '',
      createdAt: new Date().toISOString(),
    };

    CommunityService.inMemoryGroups.set(id, newGroup);

    const dbGroup = {
      id,
      title: newGroup.title,
      subtitle: newGroup.subtitle,
      members: newGroup.members,
      online: newGroup.online,
      iconName: newGroup.iconName,
      colorHex: newGroup.colorHex,
      badge: newGroup.badge,
      lastMsg: newGroup.lastMsg,
      createdBy: newGroup.adminEmail || null,
      createdAt: newGroup.createdAt,
    };

    try {
      const { data, error } = await this.db
        .from('CommunityGroup')
        .insert(dbGroup)
        .select()
        .single();
      if (data) {
        CommunityService.inMemoryGroups.set(id, {
          ...data,
          adminEmail: data.createdBy || '',
          adminName: newGroup.adminName,
        });
      }
    } catch (e) {
      console.warn('Fallback createSmartGroup in-memory save:', e);
    }

    return { success: true, data: CommunityService.inMemoryGroups.get(id) || newGroup };
  }

  async getGroupMessages(groupId: string) {
    const memMsgs = CommunityService.inMemoryGroupMessages.get(groupId) || [];
    try {
      const { data: dbMsgs, error } = await this.db
        .from('CommunityGroupMessage')
        .select('*')
        .eq('groupId', groupId)
        .order('createdAt', { ascending: true });

      const msgMap = new Map<string, any>();
      if (dbMsgs && dbMsgs.length > 0) {
        dbMsgs.forEach((m: any) => {
          msgMap.set(m.id || `${m.sender}_${m.text}_${m.time}`, m);
          if (!memMsgs.some((x: any) => x.id === m.id)) {
            memMsgs.push(m);
          }
        });
        CommunityService.inMemoryGroupMessages.set(groupId, memMsgs);
      }
      memMsgs.forEach((m: any) => msgMap.set(m.id || `${m.sender}_${m.text}_${m.time}`, m));

      const merged = Array.from(msgMap.values());
      merged.sort((a, b) => new Date(a.createdAt || 0).getTime() - new Date(b.createdAt || 0).getTime());
      return { success: true, data: merged };
    } catch (e) {
      console.warn('[CommunityService] Error fetching messages from DB, using cache:', e);
      return { success: true, data: memMsgs };
    }
  }

  async sendGroupMessage(groupId: string, msgData: any) {
    const now = new Date();
    const timeStr = `${now.getHours() % 12 === 0 ? 12 : now.getHours() % 12}:${now.getMinutes().toString().padStart(2, '0')} ${now.getHours() >= 12 ? 'PM' : 'AM'}`;

    const rawText = msgData.text || '';
    const maskedText = this.maskPhoneNumbers(rawText);

    const newMsg = {
      id: msgData.id || `msg_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      groupId,
      sender: msgData.sender || 'Student User',
      avatarLetter: msgData.avatarLetter || (msgData.sender ? msgData.sender[0] : 'S'),
      colorHex: msgData.colorHex || '#311B92',
      role: msgData.role || 'Student',
      text: maskedText,
      time: timeStr,
      isMe: false,
      createdAt: now.toISOString(),
    };

    // Store in shared in-memory list
    if (!CommunityService.inMemoryGroupMessages.has(groupId)) {
      CommunityService.inMemoryGroupMessages.set(groupId, []);
    }
    CommunityService.inMemoryGroupMessages.get(groupId)!.push(newMsg);

    // Update last message in group
    const lastMsgText = `${newMsg.sender}: ${newMsg.text}`;
    if (CommunityService.inMemoryGroups.has(groupId)) {
      const grp = CommunityService.inMemoryGroups.get(groupId);
      grp.lastMsg = lastMsgText;
      grp.updatedAt = now.toISOString();
    }

    try {
      // 1. Ensure parent group exists in DB
      if (CommunityService.inMemoryGroups.has(groupId)) {
        const parentGrp = CommunityService.inMemoryGroups.get(groupId);
        await this.db
          .from('CommunityGroup')
          .upsert({
            id: parentGrp.id,
            title: parentGrp.title,
            subtitle: parentGrp.subtitle || '',
            members: parentGrp.members || 1,
            online: parentGrp.online || 1,
            iconName: parentGrp.iconName || 'school_rounded',
            colorHex: parentGrp.colorHex || '#311B92',
            badge: parentGrp.badge || 'General',
            lastMsg: lastMsgText,
            updatedAt: now.toISOString(),
          }, { onConflict: 'id' });
      }

      // 2. Persist message permanently in database
      const { error: insertError } = await this.db
        .from('CommunityGroupMessage')
        .upsert(newMsg, { onConflict: 'id' });

      if (insertError) {
        console.error('[CommunityService] DB insert error for group message:', insertError);
      } else {
        console.log('[CommunityService] Message stored successfully in database:', newMsg.id);
      }
    } catch (e) {
      console.warn('Fallback sendGroupMessage save:', e);
    }

    return { success: true, data: newMsg };
  }

  async deleteGroupMessage(groupId: string, messageId: string) {
    // 1. Remove from in-memory cache
    if (CommunityService.inMemoryGroupMessages.has(groupId)) {
      const list = CommunityService.inMemoryGroupMessages.get(groupId) || [];
      const filtered = list.filter((m: any) => m.id !== messageId);
      CommunityService.inMemoryGroupMessages.set(groupId, filtered);

      // Update parent group lastMsg
      if (CommunityService.inMemoryGroups.has(groupId)) {
        const grp = CommunityService.inMemoryGroups.get(groupId);
        const newLastMsg = filtered.length > 0
          ? `${filtered[filtered.length - 1].sender}: ${filtered[filtered.length - 1].text}`
          : '';
        grp.lastMsg = newLastMsg;
        grp.updatedAt = new Date().toISOString();
        try {
          await this.db
            .from('CommunityGroup')
            .update({ lastMsg: newLastMsg, updatedAt: grp.updatedAt })
            .eq('id', groupId);
        } catch (_) {}
      }
    }

    // 2. Hard delete directly from PostgreSQL / Supabase CommunityGroupMessage table
    try {
      const { error } = await this.db
        .from('CommunityGroupMessage')
        .delete()
        .eq('id', messageId);

      if (error) {
        console.error('[CommunityService] Error deleting message from DB:', error);
      } else {
        console.log(`[CommunityService] Message ${messageId} successfully deleted from database table CommunityGroupMessage`);
      }
    } catch (e) {
      console.error('[CommunityService] Exception deleting message from DB:', e);
    }

    return { success: true, message: 'Message deleted from database successfully' };
  }

  async joinGroup(groupId: string, userId?: string) {
    try {
      const { data: group } = await this.db
        .from('CommunityGroup')
        .select('members')
        .eq('id', groupId)
        .maybeSingle();

      const newCount = (group?.members || 1) + 1;
      await this.db
        .from('CommunityGroup')
        .update({ members: newCount })
        .eq('id', groupId);

      return { success: true, message: 'Joined group successfully', members: newCount };
    } catch (e) {
      return { success: true, message: 'Joined group' };
    }
  }

  async requestGroupJoin(groupId: string, reqData: any) {
    try {
      const requestObj = {
        id: `req_${Date.now()}`,
        groupId,
        applicantEmail: reqData.applicantEmail || 'student@vidhyaloan.com',
        applicantName: reqData.applicantName || 'Student Applicant',
        status: 'PENDING',
        createdAt: new Date().toISOString(),
      };

      try {
        await this.db.from('CommunityGroupJoinRequest').insert(requestObj);
      } catch (_) {}

      return {
        success: true,
        message: 'Join request sent to group admin successfully!',
        data: requestObj,
      };
    } catch (e) {
      return { success: true, message: 'Join request sent to group admin' };
    }
  }

  async getGroupJoinRequests(groupId: string) {
    try {
      const { data, error } = await this.db
        .from('CommunityGroupJoinRequest')
        .select('*')
        .eq('groupId', groupId)
        .eq('status', 'PENDING')
        .order('createdAt', { ascending: false });

      if (error || !data) return { success: true, data: [] };
      return { success: true, data };
    } catch (e) {
      return { success: true, data: [] };
    }
  }

  async approveGroupJoinRequest(groupId: string, reqId: string) {
    try {
      await this.db
        .from('CommunityGroupJoinRequest')
        .update({ status: 'APPROVED' })
        .eq('id', reqId);

      const { data: group } = await this.db
        .from('CommunityGroup')
        .select('members')
        .eq('id', groupId)
        .maybeSingle();

      const newCount = (group?.members || 1) + 1;
      await this.db
        .from('CommunityGroup')
        .update({ members: newCount })
        .eq('id', groupId);

      return { success: true, message: 'Request approved successfully', members: newCount };
    } catch (e) {
      return { success: true, message: 'Request approved' };
    }
  }
}


