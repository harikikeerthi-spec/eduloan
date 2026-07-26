import { ConnectedService } from './connected.service';
import { CreateCohortApplicationDto } from './dto/create-cohort-application.dto';
export declare class ConnectedController {
    private readonly connectedService;
    constructor(connectedService: ConnectedService);
    create(dto: CreateCohortApplicationDto): Promise<{
        success: boolean;
        id: any;
    }> | {
        success: boolean;
        message: string;
    };
    findAll(status?: string): Promise<any[]>;
    updateStatus(id: string, body: {
        status: string;
        reviewedBy?: string;
        reviewNotes?: string;
    }): Promise<any> | {
        success: boolean;
        message: string;
    };
}
