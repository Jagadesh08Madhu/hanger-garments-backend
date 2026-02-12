import app from './src/app.js';
import { PORT, NODE_ENV } from './src/config/index.js';
import prisma from './src/config/database.js';
import logger from './src/utils/logger.js';
import bcrypt from 'bcryptjs';

const createAdminIfNotExists = async () => {
  const existingAdmin = await prisma.user.findFirst({
    where: { email: process.env.ADMIN_EMAIL }
  });

  if (!existingAdmin) {
    const hashedPassword = await bcrypt.hash(process.env.ADMIN_PASSWORD, 10);

    await prisma.user.create({
      data: {
        email: process.env.ADMIN_EMAIL,
        password: hashedPassword,
        name: "Super Admin",
        role: "ADMIN",
        isActive: true,
        isApproved: true
      }
    });

    logger.info("✅ Admin user created");
  } else {
    logger.info("ℹ️ Admin already exists");
  }
};

// Test database connection on startup
async function startServer() {
  try {
    // Test database connection
    await prisma.$queryRaw`SELECT 1`;
    logger.info('✅ Database connection established successfully');

    await createAdminIfNotExists();
    // Start server
    app.listen(PORT, () => {
      logger.info(`🚀 Server running on port ${PORT}`);
      logger.info(`🌍 Environment: ${NODE_ENV}`);
      logger.info(`📚 API: http://localhost:${PORT}/api`);
      logger.info(`❤️ Health: http://localhost:${PORT}/health`);
    });
  } catch (error) {
    logger.error('❌ Failed to start server:', error);
    logger.error('💡 Please ensure:');
    logger.error('   1. Database is running and accessible');
    logger.error('   2. DATABASE_URL environment variable is set correctly');
    logger.error('   3. Prisma Client is generated (run: npx prisma generate)');
    process.exit(1);
  }
}

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('💥 Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('💥 Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('👋 SIGTERM received');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('👋 SIGINT received');
  process.exit(0);
});

// Start the server
startServer();