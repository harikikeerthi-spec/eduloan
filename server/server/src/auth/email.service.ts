import { Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
    private transporter;

    constructor() {
        this.transporter = nodemailer.createTransport({
            host: 'smtp.gmail.com',
            port: 587,
            secure: false, // true for 465, false for other ports
            auth: {
                user: process.env.EMAIL_USER,
                pass: process.env.EMAIL_PASS,
            },
        });
    }

    async sendOtp(email: string, otp: string) {
        // Keep logging for backup/debugging
        console.log(`[EmailService] ----------------------------`);
        console.log(`[EmailService] Sending OTP to ${email}: ${otp}`);
        console.log(`[EmailService] ----------------------------`);

        const mailOptions = {
            from: process.env.EMAIL_USER,
            to: email,
            subject: 'Your EduLoan OTP',
            text: `Your OTP for EduLoan is: ${otp}`,
            html: `
        <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
          <h2 style="color: #333;">EduLoan Verification</h2>
          <p>Your One-Time Password (OTP) is:</p>
          <h1 style="color: #4CAF50; letter-spacing: 5px;">${otp}</h1>
          <p>This code is valid for 10 minutes.</p>
        </div>
      `,
        };

        try {
            await this.transporter.sendMail(mailOptions);
            console.log(`[EmailService] Email sent successfully to ${email}`);
            return true;
        } catch (error) {
            console.error('[EmailService] Error sending email:', error);
            // Don't throw error to client, just log it. Client will rely on terminal log if email fails.
            return false;
        }
    }
}
