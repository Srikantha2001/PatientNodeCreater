/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * This code uses the BullMQ queue system, which is built on top of Redis
 */

import IORedis, { Redis, RedisOptions } from 'ioredis';

import * as config from './config';
import { logger } from './logger';

export const isMaxmemoryPolicyNoeviction = async (): Promise<boolean> => {
  let redis: Redis | undefined;

  const redisOptions: RedisOptions = {
    port: config.redisPort,
    host: config.redisHost,
    username: config.redisUsername,
    password: config.redisPassword,
  };

  logger.debug(redisOptions);

  try {
    redis = new IORedis(redisOptions);

    const maxmemoryPolicyConfig = await (redis as Redis).config(
      'GET',
      'maxmemory-policy'
    );
    logger.debug({ maxmemoryPolicyConfig }, 'Got maxmemory-policy config');

    if (
      maxmemoryPolicyConfig.length == 2 &&
      'maxmemory-policy' === maxmemoryPolicyConfig[0] &&
      'noeviction' === maxmemoryPolicyConfig[1]
    ) {
      return true;
    }
  } finally {
    if (redis != undefined) {
      redis.disconnect();
    }
  }

  return false;
};
