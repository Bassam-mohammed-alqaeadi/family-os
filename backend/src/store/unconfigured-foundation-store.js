import { HttpError } from '../http-error.js';

export class UnconfiguredFoundationStore {
  configured = false;

  async health() {
    return { available: false, reason: 'database_not_configured' };
  }

  async close() {}

  unavailable() {
    throw new HttpError(
      503,
      'database_not_configured',
      'Durable family data is not configured for this environment.',
    );
  }

  async listMyFamilies() {
    this.unavailable();
  }

  async createFamily() {
    this.unavailable();
  }

  async getFamily() {
    this.unavailable();
  }

  async listFamilyChildren() {
    this.unavailable();
  }

  async createFamilyChild() {
    this.unavailable();
  }

  async listFamilyDevices() {
    this.unavailable();
  }

  async registerFamilyChildDevice() {
    this.unavailable();
  }

  async createDevicePairing() {
    this.unavailable();
  }

  async claimDevicePairing() {
    this.unavailable();
  }

  async ingestDeviceTelemetry() {
    this.unavailable();
  }

  async createMembershipInvitation() {
    this.unavailable();
  }

  async acceptMembershipInvitation() {
    this.unavailable();
  }

  async revokeMembership() {
    this.unavailable();
  }

  async createGuardianTransfer() {
    this.unavailable();
  }

  async acceptGuardianTransfer() {
    this.unavailable();
  }

  async cancelGuardianTransfer() {
    this.unavailable();
  }

  async listAuditEvents() {
    this.unavailable();
  }
}
