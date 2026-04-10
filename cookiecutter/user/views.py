# -*- coding: utf-8 -*-
"""User views."""
from flask import Blueprint, render_template, request
from flask_login import login_required, current_user
from cookiecutter.user.models import Note

blueprint = Blueprint("user", __name__, url_prefix="/users", static_folder="../static")


@blueprint.route("/")
@login_required
def members():
    """List members."""
    return render_template("users/members.html")

@blueprint.route("/notes", methods=["GET", "POST"])
@login_required
def notes():
    if request.method == "POST":
        Note.create(
            content=request.form["content"],
            user_id=current_user.id
        )

    notes = Note.query.filter_by(user_id=current_user.id).all()
    return render_template("users/notes.html", notes=notes)