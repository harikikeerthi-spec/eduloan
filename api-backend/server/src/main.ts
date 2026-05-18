import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  try {
    const express = require('express');
    const app = await NestFactory.create(AppModule);
    
    // Increase payload limits for large image uploads (e.g., base64 profile pictures)
    app.use(express.json({ limit: '10mb' }));
    app.use(express.urlencoded({ limit: '10mb', extended: true }));
    
    app.enableCors();

    // LOGGING MIDDLEWARE
    app.use((req, res, next) => {
      console.log(`[REQUEST] ${req.method} ${req.url} from ${req.ip}`);
      next();
    });

    const port = process.env.PORT || 5000;
    console.log(`Attempting to listen on port ${port}...`);
    await app.listen(port, '0.0.0.0');
    console.log(`Server successfully started listening on port ${port}`);
    console.log(`Server running on http://localhost:${port}`);
    console.log(`Android Emulator: http://10.0.2.2:${port}`);
  } catch (err) {
    console.error('FATAL ERROR DURING BOOTSTRAP:', err);
    process.exit(1);
  }
}
bootstrap();
