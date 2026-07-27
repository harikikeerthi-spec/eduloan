import { Module, forwardRef } from '@nestjs/common';
import { ApplicationController } from './application.controller';
import { ApplicationService } from './application.service';
import { AdminApplicationController } from './admin-application.controller';
import { AdminApplicationService } from './admin-application.service';
import { AuthModule } from '../auth/auth.module';
import { AiModule } from '../ai/ai.module';
import { IntegrationModule } from '../integration/integration.module';
import { DocumentModule } from '../document/document.module';
import { BankModule } from '../bank/bank.module';
import { EvvEngineService } from './evv-engine';

@Module({
    imports: [AuthModule, AiModule, IntegrationModule, forwardRef(() => DocumentModule), BankModule],
    controllers: [ApplicationController, AdminApplicationController],
    providers: [ApplicationService, AdminApplicationService, EvvEngineService],
    exports: [ApplicationService, AdminApplicationService],
})
export class ApplicationModule { }
