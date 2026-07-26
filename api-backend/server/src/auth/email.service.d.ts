export declare class EmailService {
    private transporter;
    constructor();
    sendOtp(email: string, otp: string): Promise<void>;
    sendDigilockerConsentRequest(email: string, consentLink: string, documentTypes: string[]): Promise<void>;
    sendMail(to: string, subject: string, html: string, text?: string, replyTo?: string): Promise<void>;
    sendWelcomeEmail(email: string, firstName?: string): Promise<void>;
}
