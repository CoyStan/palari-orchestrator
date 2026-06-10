"""The test suite is adversarial by design: one honest path that must be
accepted, and a battery of attacks that must each be refused for the right
reason. Run with: python -m unittest discover tests -v
"""
import unittest

from forgegate import attest as att
from forgegate import gate
from forgegate import token as tok
from forgegate.canon import digest_bytes
from forgegate.keys import Key
from forgegate.layout import validate

EXP = "2099-01-01T00:00:00+00:00"
COMMIT = "a" * 40
TICKET = "T-42"
BRANCH = "feat/x"

LAYOUT = validate({
    "name": "code-change",
    "steps": [
        {"name": "implement"},
        {"name": "test", "consumes": ["implement"]},
        {"name": "review", "consumes": ["test"], "distinct_from": ["implement"]},
    ],
})


class Harness(unittest.TestCase):
    def setUp(self):
        self.root = Key.generate()
        self.orch = Key.generate()
        self.impl = Key.generate()
        self.test = Key.generate()
        self.review = Key.generate()

        self.org_tok = tok.mint(
            self.root, self.orch.public_hex,
            tok.scope(TICKET, BRANCH, ["*"], EXP))
        self.impl_tok = self._grant(self.impl, ["implement"])
        self.test_tok = self._grant(self.test, ["test"])
        self.review_tok = self._grant(self.review, ["review"])

        self.code = digest_bytes(b"fn add(a:i64,b:i64)->i64{a+b}")
        self.report = digest_bytes(b"3 passed, 0 failed")
        self.approval = digest_bytes(b"LGTM")

    def _grant(self, key, steps, exp=EXP):
        return tok.attenuate(
            self.org_tok, self.orch, key.public_hex,
            tok.scope(TICKET, BRANCH, steps, exp))

    def _honest(self):
        a1 = att.create(self.impl, self.impl_tok, "implement", TICKET, BRANCH,
                        {}, {"src": self.code}, COMMIT)
        a2 = att.create(self.test, self.test_tok, "test", TICKET, BRANCH,
                        {"src": self.code}, {"report": self.report}, COMMIT)
        a3 = att.create(self.review, self.review_tok, "review", TICKET, BRANCH,
                        {"report": self.report}, {"approval": self.approval},
                        COMMIT)
        return [a1, a2, a3]

    def _verify(self, atts, commit=COMMIT):
        return gate.verify(atts, LAYOUT, self.root.public_hex,
                           TICKET, BRANCH, commit)


class TestHonestPath(Harness):
    def test_honest_run_is_accepted(self):
        v = self._verify(self._honest())
        self.assertTrue(v, v.reasons)


class TestForgery(Harness):
    def test_implementer_cannot_forge_a_test_pass(self):
        """The canonical attack: a confused or injected implement-agent
        writes 'tests passed' itself. Hashes are valid. Must be refused."""
        a1, _, a3 = self._honest()
        forged = att.create(self.impl, self.impl_tok, "test", TICKET, BRANCH,
                            {"src": self.code}, {"report": self.report}, COMMIT)
        v = self._verify([a1, forged, a3])
        self.assertFalse(v)
        self.assertTrue(any("does not authorize" in r for r in v.reasons))

    def test_tampered_attestation_is_refused(self):
        atts = self._honest()
        atts[1]["outputs"]["report"] = digest_bytes(b"0 passed, 3 failed")
        v = self._verify(atts)
        self.assertFalse(v)
        self.assertTrue(any("signature invalid" in r for r in v.reasons))

    def test_stolen_token_is_useless_to_a_different_key(self):
        """A valid token presented by a key that does not hold it."""
        a1, _, a3 = self._honest()
        thief = Key.generate()
        stolen = att.create(thief, self.test_tok, "test", TICKET, BRANCH,
                            {"src": self.code}, {"report": self.report}, COMMIT)
        v = self._verify([a1, stolen, a3])
        self.assertFalse(v)
        self.assertTrue(any("not the token holder" in r for r in v.reasons))

    def test_foreign_root_is_rejected(self):
        """A complete, internally valid evidence chain from another trust
        domain must not open this gate."""
        other_root = Key.generate()
        other_orch = Key.generate()
        o_tok = tok.mint(other_root, other_orch.public_hex,
                         tok.scope(TICKET, BRANCH, ["*"], EXP))
        atts = [
            att.create(other_orch, o_tok, s, TICKET, BRANCH,
                       {}, {}, COMMIT)
            for s in ("implement", "test", "review")
        ]
        v = self._verify(atts)
        self.assertFalse(v)
        self.assertTrue(any("token rejected" in r for r in v.reasons))


class TestDelegation(Harness):
    def test_attenuation_cannot_widen_scope(self):
        with self.assertRaises(ValueError):
            tok.attenuate(self.impl_tok, self.impl, Key.generate().public_hex,
                          tok.scope(TICKET, BRANCH, ["implement", "test"], EXP))

    def test_hand_widened_chain_is_refused_by_verifier(self):
        """Even if an attacker writes the widened block by hand, the chain
        walk rejects it."""
        # Correct linkage, widened scope, signed by the real holder.
        from forgegate.canon import digest as d
        widened_body = {
            "v": 1, "holder": self.impl.public_hex,
            "scope": tok.scope(TICKET, BRANCH, ["implement", "test"], EXP),
            "prev": d(self.impl_tok[-1]),
        }
        block = {**widened_body, "sig": self.impl.sign(widened_body)}
        bad_chain = self.impl_tok + [block]
        ok, why = tok.verify_chain(bad_chain, self.root.public_hex)
        self.assertFalse(ok)
        self.assertIn("widened", why)

    def test_expired_token_is_refused(self):
        expired = self._grant(self.test, ["test"],
                              exp="2000-01-01T00:00:00+00:00")
        a1, _, a3 = self._honest()
        late = att.create(self.test, expired, "test", TICKET, BRANCH,
                          {"src": self.code}, {"report": self.report}, COMMIT)
        v = self._verify([a1, late, a3])
        self.assertFalse(v)

    def test_only_holder_may_attenuate(self):
        with self.assertRaises(ValueError):
            tok.attenuate(self.impl_tok, self.test, Key.generate().public_hex,
                          tok.scope(TICKET, BRANCH, ["implement"], EXP))


class TestFlowAndBinding(Harness):
    def test_broken_hash_flow_is_refused(self):
        """Tests that ran against different bytes than were implemented."""
        a1, _, a3 = self._honest()
        other = digest_bytes(b"something else entirely")
        drifted = att.create(self.test, self.test_tok, "test", TICKET, BRANCH,
                             {"src": other}, {"report": self.report}, COMMIT)
        v = self._verify([a1, drifted, a3])
        self.assertFalse(v)
        self.assertTrue(any("does not match output" in r for r in v.reasons))

    def test_wrong_commit_binding_is_refused(self):
        v = self._verify(self._honest(), commit="b" * 40)
        self.assertFalse(v)
        self.assertTrue(any("different commit" in r for r in v.reasons))

    def test_missing_step_is_refused(self):
        a1, a2, _ = self._honest()
        v = self._verify([a1, a2])
        self.assertFalse(v)
        self.assertTrue(any("no attestation" in r for r in v.reasons))


class TestDualControl(Harness):
    def test_self_review_is_refused(self):
        """The implementer approving its own work, with a perfectly valid
        review-scoped token, must still be refused."""
        a1, a2, _ = self._honest()
        self_review_tok = self._grant(self.impl, ["review"])
        a3 = att.create(self.impl, self_review_tok, "review", TICKET, BRANCH,
                        {"report": self.report}, {"approval": self.approval},
                        COMMIT)
        v = self._verify([a1, a2, a3])
        self.assertFalse(v)
        self.assertTrue(any("different key" in r for r in v.reasons))


class TestTicketsArePureData(Harness):
    def test_injected_instructions_grant_nothing(self):
        """A ticket carrying hostile frontmatter changes no outcome: the
        gate never reads tickets, only tokens and attestations. Modeled here
        by an agent that obeyed an injection and attempted out-of-scope
        work; refusal is identical regardless of what the ticket said."""
        a1, _, a3 = self._honest()
        obeyed_injection = att.create(
            self.impl, self.impl_tok, "test", TICKET, BRANCH,
            {"src": self.code}, {"report": self.report}, COMMIT)
        v = self._verify([a1, obeyed_injection, a3])
        self.assertFalse(v)


class TestCodexFindings(Harness):
    """Tests for the issues raised in external review."""

    def test_backdated_attestation_refused_under_verify_time_policy(self):
        """A signer backdates ts into an expired token's validity window.
        With verify_time + max_age, the gate refuses it."""
        expired = self._grant(self.test, ["test"],
                              exp="2020-01-01T00:00:00+00:00")
        a1, _, a3 = self._honest()
        backdated = att.create(self.test, expired, "test", TICKET, BRANCH,
                               {"src": self.code}, {"report": self.report},
                               COMMIT, ts="2019-12-31T00:00:00+00:00")
        v = gate.verify([a1, backdated, a3], LAYOUT, self.root.public_hex,
                        TICKET, BRANCH, COMMIT,
                        verify_time="2026-06-10T00:00:00+00:00",
                        max_age_seconds=86400)
        self.assertFalse(v)
        self.assertTrue(any("older than accepted window" in r
                            for r in v.reasons))

    def test_future_dated_attestation_is_refused(self):
        a1, a2, _ = self._honest()
        future = att.create(self.review, self.review_tok, "review", TICKET,
                            BRANCH, {"report": self.report},
                            {"approval": self.approval}, COMMIT,
                            ts="2098-01-01T00:00:00+00:00")
        v = gate.verify([a1, a2, future], LAYOUT, self.root.public_hex,
                        TICKET, BRANCH, COMMIT,
                        verify_time="2026-06-10T00:00:00+00:00")
        self.assertFalse(v)
        self.assertTrue(any("future" in r for r in v.reasons))

    def test_duplicate_attestations_are_ambiguous_and_refused(self):
        a1, a2, a3 = self._honest()
        a2b = att.create(self.test, self.test_tok, "test", TICKET, BRANCH,
                         {"src": self.code},
                         {"report": digest_bytes(b"0 passed")}, COMMIT)
        v = self._verify([a1, a2, a2b, a3])
        self.assertFalse(v)
        self.assertTrue(any("ambiguous" in r for r in v.reasons))

    def test_malformed_evidence_fails_closed_not_loud(self):
        garbage = [{"ticket": TICKET, "step": "implement"},
                   "not even a dict", {"ticket": TICKET, "step": "test",
                                       "token": "nonsense"}]
        try:
            v = self._verify(garbage)
        except Exception as e:  # pragma: no cover
            self.fail(f"gate raised instead of refusing: {e}")
        self.assertFalse(v)

    def test_constraint_scopes_narrow_and_enforce(self):
        """Path-scoped delegation: work that touches files outside the
        allowed paths is refused; attenuation cannot widen the path set."""
        scoped = tok.attenuate(
            self.org_tok, self.orch, self.impl.public_hex,
            tok.scope(TICKET, BRANCH, ["implement"], EXP,
                      constraints={"paths": ["src/"]}))
        ok = att.create(self.impl, scoped, "implement", TICKET, BRANCH,
                        {}, {"src": self.code}, COMMIT,
                        context={"paths": ["src/"]})
        bad = att.create(self.impl, scoped, "implement", TICKET, BRANCH,
                         {}, {"src": self.code}, COMMIT,
                         context={"paths": ["src/", "secrets/"]})
        lay = validate({"name": "x", "steps": [{"name": "implement"}]})
        self.assertTrue(gate.verify([ok], lay, self.root.public_hex,
                                    TICKET, BRANCH, COMMIT))
        v = gate.verify([bad], lay, self.root.public_hex,
                        TICKET, BRANCH, COMMIT)
        self.assertFalse(v)
        # Widening the constraint during delegation is refused.
        with self.assertRaises(ValueError):
            tok.attenuate(scoped, self.impl, Key.generate().public_hex,
                          tok.scope(TICKET, BRANCH, ["implement"], EXP,
                                    constraints={"paths": ["src/", "infra/"]}))
        # Dropping the constraint entirely during delegation is also refused.
        with self.assertRaises(ValueError):
            tok.attenuate(scoped, self.impl, Key.generate().public_hex,
                          tok.scope(TICKET, BRANCH, ["implement"], EXP))


class TestStoreFailsClosed(Harness):
    """FG-STORE-001: corrupt or non-dict evidence in the store must never
    raise, and verification must still reach a REFUSED verdict."""

    def _poisoned_store(self, tmp):
        import json as j
        import os
        from forgegate.store import FileStore
        fs = FileStore(tmp)
        a1, a2, a3 = self._honest()
        fs.put(a1)  # only one honest attestation; test/review missing
        d = fs.dir
        with open(os.path.join(d, "zz-string.json"), "w") as f:
            j.dump("not even a dict", f)
        with open(os.path.join(d, "zz-list.json"), "w") as f:
            j.dump([1, 2, 3], f)
        with open(os.path.join(d, "zz-noticket.json"), "w") as f:
            j.dump({"step": "test"}, f)
        with open(os.path.join(d, "zz-broken.json"), "w") as f:
            f.write("{this is not json")
        return fs

    def test_for_ticket_never_raises_and_verify_refuses(self):
        import tempfile
        with tempfile.TemporaryDirectory() as tmp:
            fs = self._poisoned_store(tmp)
            try:
                atts = fs.for_ticket(TICKET)
            except Exception as e:  # pragma: no cover
                self.fail(f"store raised on corrupt evidence: {e}")
            self.assertEqual(len(atts), 1)
            self.assertEqual(len(fs.skipped), 3)  # string, list, broken json
            v = self._verify(atts)
            self.assertFalse(v)
            self.assertTrue(any("no attestation" in r for r in v.reasons))


class TestGlobConstraints(Harness):
    def test_glob_patterns_authorize_real_paths(self):
        scoped = tok.attenuate(
            self.org_tok, self.orch, self.impl.public_hex,
            tok.scope(TICKET, BRANCH, ["implement"], EXP,
                      constraints={"paths": ["src/*", "docs/positioning/*"]}))
        lay = validate({"name": "x", "steps": [{"name": "implement"}]})
        ok = att.create(self.impl, scoped, "implement", TICKET, BRANCH,
                        {}, {"src": self.code}, COMMIT,
                        context={"paths": ["src/api/handlers.py",
                                           "docs/positioning/launch.md"]})
        self.assertTrue(gate.verify([ok], lay, self.root.public_hex,
                                    TICKET, BRANCH, COMMIT))
        bad = att.create(self.impl, scoped, "implement", TICKET, BRANCH,
                         {}, {"src": self.code}, COMMIT,
                         context={"paths": ["src/api/handlers.py",
                                            "secrets/prod.env"]})
        v = gate.verify([bad], lay, self.root.public_hex,
                        TICKET, BRANCH, COMMIT)
        self.assertFalse(v)

    def test_narrowing_globs_stays_literal_not_clever(self):
        """src/api/* plausibly 'narrows' src/*, but pattern containment is
        where escalation bugs live; the kernel refuses to guess."""
        scoped = tok.attenuate(
            self.org_tok, self.orch, self.impl.public_hex,
            tok.scope(TICKET, BRANCH, ["implement"], EXP,
                      constraints={"paths": ["src/*"]}))
        with self.assertRaises(ValueError):
            tok.attenuate(scoped, self.impl, Key.generate().public_hex,
                          tok.scope(TICKET, BRANCH, ["implement"], EXP,
                                    constraints={"paths": ["src/api/*"]}))


class TestRequiredContext(Harness):
    """FG-CONSTRAINT-001: a constrained token does not authorize work that
    declines to report the constrained dimension."""

    def _scoped(self):
        return tok.attenuate(
            self.org_tok, self.orch, self.impl.public_hex,
            tok.scope(TICKET, BRANCH, ["implement"], EXP,
                      constraints={"paths": ["marketing/*"]}))

    def _att(self, context):
        return att.create(self.impl, self._scoped(), "implement", TICKET,
                          BRANCH, {}, {"out": self.code}, COMMIT,
                          context=context)

    def _gate(self, a, lay=None):
        lay = lay or validate({"name": "x", "steps": [{"name": "implement"}]})
        return gate.verify([a], lay, self.root.public_hex,
                           TICKET, BRANCH, COMMIT)

    def test_missing_context_is_refused(self):
        v = self._gate(self._att(None))
        self.assertFalse(v)
        self.assertTrue(any("missing required constraint context: paths" in r
                            for r in v.reasons))

    def test_empty_context_is_refused(self):
        v = self._gate(self._att({"paths": []}))
        self.assertFalse(v)
        self.assertTrue(any("missing required constraint" in r
                            for r in v.reasons))

    def test_matching_path_is_accepted(self):
        v = self._gate(self._att({"paths": ["marketing/campaign.md"]}))
        self.assertTrue(v, v.reasons)

    def test_nonmatching_path_is_refused(self):
        v = self._gate(self._att({"paths": ["secrets/prod.env"]}))
        self.assertFalse(v)

    def test_layout_may_mark_dimension_optional(self):
        lay = validate({"name": "x", "steps": [
            {"name": "implement", "optional_context": ["paths"]}]})
        v = self._gate(self._att(None), lay)
        self.assertTrue(v, v.reasons)
        # values reported under an optional dimension are still checked
        v2 = self._gate(self._att({"paths": ["secrets/prod.env"]}), lay)
        self.assertFalse(v2)


if __name__ == "__main__":
    unittest.main(verbosity=2)
