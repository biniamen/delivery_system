using System.Collections.Concurrent;
using Creavers.Delivery.Application.Onboarding;

namespace Creavers.Delivery.Infrastructure.Authentication;

public sealed class MemoryOtpChallengeStore : IOtpChallengeStore
{
    private readonly ConcurrentDictionary<Guid, OtpChallengeState> _challenges = new();

    public OtpChallengeState? FindChallenge(Guid challengeId) =>
        _challenges.GetValueOrDefault(challengeId);

    public void SaveChallenge(OtpChallengeState challenge) =>
        _challenges[challenge.Id] = challenge;

    public void RemoveChallenge(Guid challengeId) =>
        _challenges.TryRemove(challengeId, out _);
}
