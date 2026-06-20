"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var EmailService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.EmailService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const nodemailer = __importStar(require("nodemailer"));
let EmailService = EmailService_1 = class EmailService {
    configService;
    logger = new common_1.Logger(EmailService_1.name);
    transporter;
    constructor(configService) {
        this.configService = configService;
        this.initializeTransporter();
    }
    initializeTransporter() {
        const host = this.configService.get('EMAIL_HOST') || 'smtp.gmail.com';
        const port = this.configService.get('EMAIL_PORT') || 587;
        const user = this.configService.get('EMAIL_USER');
        const pass = this.configService.get('EMAIL_PASS');
        const from = this.configService.get('EMAIL_FROM') || `"VidyaLoan" <${user}>`;
        this.transporter = nodemailer.createTransport({
            host,
            port,
            secure: port === 465,
            auth: { user, pass },
            from,
        });
    }
    async sendChatNotificationEmail(to, senderName, senderRole, message, conversationContext) {
        try {
            const htmlContent = `
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #6605c7 0%, #5504a6 100%); padding: 40px; border-radius: 16px; color: white; text-align: center; margin-bottom: 30px;">
            <h1 style="margin: 0; font-size: 28px; font-weight: bold;">VidyaLoan</h1>
            <p style="margin: 10px 0 0 0; font-size: 14px; opacity: 0.9;">New Message in Your Application</p>
          </div>

          <div style="background: #f9f9f9; padding: 30px; border-radius: 12px; margin-bottom: 30px;">
            <p style="margin: 0 0 20px 0; color: #666; font-size: 14px;">
              <strong>${senderName}</strong> (${senderRole}) has sent you a message regarding your loan application.
            </p>

            ${conversationContext.applicationNumber ? `
              <div style="background: white; padding: 15px; border-left: 4px solid #6605c7; border-radius: 4px; margin-bottom: 20px;">
                <p style="margin: 0; font-size: 12px; color: #999; text-transform: uppercase; letter-spacing: 0.5px;">Application Details</p>
                <p style="margin: 8px 0 0 0; font-size: 16px; font-weight: bold; color: #333;">
                  ${conversationContext.applicationNumber}
                  ${conversationContext.bank ? ` • ${conversationContext.bank}` : ''}
                </p>
              </div>
            ` : ''}

            <div style="background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; border: 1px solid #e0e0e0;">
              <p style="margin: 0; color: #666; font-size: 14px; line-height: 1.6; white-space: pre-wrap;">
                ${this.escapeHtml(message)}
              </p>
            </div>

            <div style="background: #f0f4ff; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
              <p style="margin: 0; color: #6605c7; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; font-weight: bold;">Subject</p>
              <p style="margin: 8px 0 0 0; color: #333; font-size: 14px;">
                ${this.escapeHtml(conversationContext.subject)}
              </p>
            </div>
          </div>

          <div style="text-align: center; margin-bottom: 30px;">
            <a href="${process.env.FRONTEND_URL || 'http://localhost:3000'}/dashboard#applications" 
               style="display: inline-block; background: linear-gradient(135deg, #6605c7 0%, #5504a6 100%); color: white; padding: 14px 40px; border-radius: 8px; text-decoration: none; font-weight: bold; font-size: 14px; text-transform: uppercase; letter-spacing: 0.5px;">
              View Application
            </a>
          </div>

          <div style="border-top: 1px solid #e0e0e0; padding-top: 20px; text-align: center; color: #999; font-size: 12px;">
            <p style="margin: 0 0 10px 0;">
              You received this email because you have an active loan application with VidyaLoan.
            </p>
            <p style="margin: 0;">
              © ${new Date().getFullYear()} VidyaLoan. All rights reserved.
            </p>
          </div>
        </div>
      `;
            await this.transporter.sendMail({
                to,
                subject: `New Message: ${conversationContext.subject}`,
                html: htmlContent,
                text: `${senderName} (${senderRole}) sent: ${message}`,
            });
            this.logger.log(`Email sent to ${to}`);
            return true;
        }
        catch (error) {
            this.logger.error(`Failed to send email to ${to}:`, error);
            return false;
        }
    }
    async sendDocumentNotificationEmail(to, documentDetails) {
        try {
            const htmlContent = `
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #6605c7 0%, #5504a6 100%); padding: 40px; border-radius: 16px; color: white; text-align: center; margin-bottom: 30px;">
            <h1 style="margin: 0; font-size: 28px; font-weight: bold;">VidyaLoan</h1>
            <p style="margin: 10px 0 0 0; font-size: 14px; opacity: 0.9;">Document Shared with You</p>
          </div>

          <div style="background: #f9f9f9; padding: 30px; border-radius: 12px; margin-bottom: 30px;">
            <p style="margin: 0 0 20px 0; color: #666; font-size: 14px;">
              A document has been shared with you by <strong>${documentDetails.uploadedBy}</strong> (${documentDetails.uploadedByRole}).
            </p>

            <div style="background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; border: 2px solid #6605c7; text-align: center;">
              <p style="margin: 0; font-size: 12px; color: #999; text-transform: uppercase; letter-spacing: 0.5px;">Document Details</p>
              <p style="margin: 12px 0 8px 0; font-size: 18px; font-weight: bold; color: #333;">
                📄 ${this.escapeHtml(documentDetails.documentName)}
              </p>
              <p style="margin: 8px 0 0 0; font-size: 12px; color: #6605c7; font-weight: bold;">
                Status: ${documentDetails.status}
              </p>
            </div>

            <div style="background: #f0f4ff; padding: 15px; border-radius: 8px;">
              <p style="margin: 0 0 10px 0; font-size: 12px; color: #6605c7; text-transform: uppercase; letter-spacing: 0.5px; font-weight: bold;">Application</p>
              <p style="margin: 0; font-size: 14px; color: #333;">
                ${documentDetails.applicationNumber}
                ${documentDetails.bank ? ` • ${documentDetails.bank}` : ''}
              </p>
            </div>
          </div>

          <div style="text-align: center;">
            <a href="${process.env.FRONTEND_URL || 'http://localhost:3000'}/document-vault" 
               style="display: inline-block; background: linear-gradient(135deg, #6605c7 0%, #5504a6 100%); color: white; padding: 14px 40px; border-radius: 8px; text-decoration: none; font-weight: bold; font-size: 14px; text-transform: uppercase; letter-spacing: 0.5px;">
              View Document
            </a>
          </div>

          <div style="border-top: 1px solid #e0e0e0; padding-top: 20px; text-align: center; color: #999; font-size: 12px; margin-top: 30px;">
            <p style="margin: 0;">© ${new Date().getFullYear()} VidyaLoan. All rights reserved.</p>
          </div>
        </div>
      `;
            await this.transporter.sendMail({
                to,
                subject: `Document Shared: ${documentDetails.documentName}`,
                html: htmlContent,
                text: `Document ${documentDetails.documentName} has been shared with you for application ${documentDetails.applicationNumber}`,
            });
            this.logger.log(`Document notification email sent to ${to}`);
            return true;
        }
        catch (error) {
            this.logger.error(`Failed to send document email to ${to}:`, error);
            return false;
        }
    }
    escapeHtml(text) {
        const map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;',
        };
        return text.replace(/[&<>"']/g, (m) => map[m]);
    }
};
exports.EmailService = EmailService;
exports.EmailService = EmailService = EmailService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], EmailService);
//# sourceMappingURL=email.service.js.map