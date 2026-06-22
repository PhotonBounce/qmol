"""CLI parity tests for the newer science commands."""
from __future__ import annotations

from typer.testing import CliRunner

from cli import cli as qmol_cli

runner = CliRunner()


def test_cli_fingerprint_morgan():
    r = runner.invoke(qmol_cli, ["fingerprint", "CCO", "c1ccccc1"])
    assert r.exit_code == 0
    assert "morgan" in r.output
    assert "on_bits=" in r.output


def test_cli_fingerprint_maccs_width():
    r = runner.invoke(qmol_cli, ["fingerprint", "CCO", "--kind", "maccs"])
    assert r.exit_code == 0
    assert "n_bits=167" in r.output


def test_cli_fingerprint_bad_smiles():
    r = runner.invoke(qmol_cli, ["fingerprint", "not-a-smiles"])
    assert r.exit_code == 0
    assert "FAIL" in r.output


def test_cli_tautomers():
    r = runner.invoke(qmol_cli, ["tautomers", "O=C1CCCCC1"])
    assert r.exit_code == 0
    assert "canonical=" in r.output


def test_cli_cluster():
    r = runner.invoke(qmol_cli, ["cluster", "CCO", "CCO", "c1ccccc1",
                                 "--cutoff", "0.3"])
    assert r.exit_code == 0
    assert "clusters" in r.output
    assert "centroid=" in r.output


def test_cli_cluster_all_invalid_exits_nonzero():
    r = runner.invoke(qmol_cli, ["cluster", "nope", "bad"])
    assert r.exit_code == 1
