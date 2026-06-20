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
exports.UniversityInquiryService = void 0;
const common_1 = require("@nestjs/common");
const supabase_service_1 = require("../supabase/supabase.service");
const email_service_1 = require("../auth/email.service");
const crypto_1 = require("crypto");
let UniversityInquiryService = class UniversityInquiryService {
    supabase;
    emailService;
    get db() {
        return this.supabase.getClient();
    }
    constructor(supabase, emailService) {
        this.supabase = supabase;
        this.emailService = emailService;
    }
    async createInquiry(data) {
        const { data: inquiry, error } = await this.db
            .from('UniversityInquiry')
            .insert({
            id: (0, crypto_1.randomUUID)(),
            userId: data.userId,
            name: data.name,
            email: data.email,
            mobile: data.mobile,
            universityName: data.universityName,
            type: data.type,
            updatedAt: new Date().toISOString(),
        })
            .select()
            .single();
        if (error)
            throw error;
        await this.sendInquiryEmails(data);
        return inquiry;
    }
    async getInquiriesByUser(userId) {
        const { data } = await this.db
            .from('UniversityInquiry')
            .select('*')
            .eq('userId', userId)
            .order('createdAt', { ascending: false });
        return data || [];
    }
    async checkInquiry(email, universityName, type) {
        const { data: existing } = await this.db
            .from('UniversityInquiry')
            .select('id')
            .eq('email', email)
            .eq('universityName', universityName)
            .eq('type', type)
            .single();
        return { exists: !!existing };
    }
    async sendInquiryEmails(data) {
        let typeLabel = data.type;
        if (data.type === 'callback') {
            typeLabel = 'Request a Callback';
        }
        else if (data.type === 'fast_track' || data.type === 'fasttrack') {
            typeLabel = 'Fasttrack Application';
        }
        else if (data.type === 'application') {
            typeLabel = 'Admission Application';
        }
        const userHtml = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e5e7eb; border-radius: 12px;">
        <div style="background: linear-gradient(135deg, #6605c7 0%, #8b5cf6 100%); padding: 30px; border-radius: 10px; text-align: center; margin-bottom: 24px;">
          <h1 style="color: white; margin: 0; font-size: 24px;">Vidya Loan</h1>
        </div>
        <div style="padding: 0 10px;">
          <h2 style="color: #111827; margin-bottom: 16px;">We've received your request!</h2>
          <p style="color: #4b5563; font-size: 16px; line-height: 1.5;">Hi ${data.name},</p>
          <p style="color: #4b5563; font-size: 16px; line-height: 1.5;">We have received your ${typeLabel.toLowerCase()} inquiry for <strong>${data.universityName}</strong>.</p>
          <div style="background: #f9fafb; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <p style="margin: 5px 0;"><strong>Name:</strong> ${data.name}</p>
            <p style="margin: 5px 0;"><strong>Mobile:</strong> ${data.mobile}</p>
            <p style="margin: 5px 0;"><strong>University:</strong> ${data.universityName}</p>
            <p style="margin: 5px 0;"><strong>Request:</strong> ${typeLabel}</p>
          </div>
          <p style="color: #4b5563; font-size: 16px;">Our education consultants will call you shortly.</p>
        </div>
      </div>
    `;
        const adminHtml = `
      <div style="font-family: Arial, sans-serif; padding: 20px;">
        <h2>New Lead Generated</h2>
        <p><strong>Name:</strong> ${data.name}</p>
        <p><strong>Email:</strong> ${data.email}</p>
        <p><strong>Mobile:</strong> ${data.mobile}</p>
        <p><strong>University:</strong> ${data.universityName}</p>
        <p><strong>Lead Type:</strong> ${typeLabel}</p>
      </div>
    `;
        try {
            await this.emailService.sendMail(data.email, `Inquiry Received: ${data.universityName}`, userHtml);
            await this.emailService.sendMail(process.env.ADMIN_EMAIL || 'admin@vidyaloan.com', `NEW LEAD: ${data.name} - ${typeLabel}`, adminHtml);
        }
        catch (e) {
            console.error('Error sending lead emails', e);
        }
    }
};
exports.UniversityInquiryService = UniversityInquiryService;
exports.UniversityInquiryService = UniversityInquiryService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [supabase_service_1.SupabaseService,
        email_service_1.EmailService])
], UniversityInquiryService);
//# sourceMappingURL=university-inquiry.service.js.map