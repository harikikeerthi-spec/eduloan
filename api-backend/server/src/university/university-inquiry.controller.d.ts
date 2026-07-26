import { UniversityInquiryService } from './university-inquiry.service';
export declare class UniversityInquiryController {
    private readonly inquiryService;
    constructor(inquiryService: UniversityInquiryService);
    create(body: {
        userId?: string;
        name: string;
        email: string;
        mobile: string;
        universityName: string;
        type: string;
    }): Promise<any>;
    check(email: string, universityName: string, type: string): Promise<{
        exists: boolean;
    }>;
}
