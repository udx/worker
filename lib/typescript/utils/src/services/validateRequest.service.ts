import Ajv, { JSONSchemaType, ValidateFunction } from 'ajv';
import addFormats from 'ajv-formats';

import { EInvalidateCacheFields, IAWSInvalidateRequest } from '../types';

export class ValidateRequestService {
  private ajv: Ajv;
  private validateFn: ValidateFunction<IAWSInvalidateRequest>;

  constructor() {
    this.ajv = new Ajv({
      removeAdditional: true,
    });

    addFormats(this.ajv);

    this.validateFn = this.ajv.compile(this.getSchema());
  }

  private getSchema(): JSONSchemaType<IAWSInvalidateRequest> {
    return {
      type: 'object',
      required: [
        EInvalidateCacheFields.AWS_ACCOUNT,
        EInvalidateCacheFields.DISTRIBUTION_ID,
        EInvalidateCacheFields.INVALIDATION_PATH,
      ],
      properties: {
        [EInvalidateCacheFields.AWS_ACCOUNT]          : { type: 'string', pattern: '^[A-Za-z0-9]{1,50}$' },
        [EInvalidateCacheFields.DISTRIBUTION_ID]      : { type: 'string', pattern: '^[A-Z0-9]{6,30}$' },
        [EInvalidateCacheFields.SLACK_WEBHOOK]        : { type: 'string', format: 'uri', nullable: true },
        [EInvalidateCacheFields.SLACK_CHANNEL]        : { type: 'string', nullable: true },
        [EInvalidateCacheFields.SLACK_USERNAME]       : { type: 'string', nullable: true },
        [EInvalidateCacheFields.SLACK_GITHUB_BRANCH]  : { type: 'string', nullable: true },
        [EInvalidateCacheFields.SLACK_SITE_URL]       : { type: 'string', nullable: true },
        [EInvalidateCacheFields.INVALIDATION_PATH]    : {
          type: 'array',
          items: { type: 'string', format: 'uri-reference' },
        },
      },
      additionalProperties: false,
    };
  }

  /**
   * Validates and filters request fields
   * @param data request payload
   * @returns IAWSInvalidateRequest
   */
  public validateRequest(data: any): IAWSInvalidateRequest {
    const result = this.validateFn(data);

    if (!result) {
      throw new Error(`Request validation error: ${JSON.stringify(this.validateFn.errors)}`);
    }

    return data;
  }
}