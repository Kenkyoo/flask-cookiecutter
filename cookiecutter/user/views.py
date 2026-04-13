# -*- coding: utf-8 -*-
"""User views."""
from flask import Blueprint, render_template, request, redirect
from flask_login import login_required, current_user
from cookiecutter.user.models import Note

from .forms import NoteForm

blueprint = Blueprint("user", __name__, url_prefix="/users", static_folder="../static")


@blueprint.route("/")
@login_required
def members():
    """List members."""
    return render_template("users/members.html")

@blueprint.route("/notes", methods=["GET", "POST"])
@login_required
def notes():
    form = NoteForm(request.form) # Instanciamos el form
    
    if form.validate_on_submit():
        Note.create(
            content=form.content.data,
            user_id=current_user.id
        )
        # Opcional: puedes añadir un flash message aquí
        return redirect(url_for("user.notes"))

    # Obtenemos las notas para mostrarlas
    notes = Note.query.filter_by(user_id=current_user.id).all()
    
    # Enviamos TANTO las notas COMO el form al template
    return render_template("users/notes.html", notes=notes, form=form)
