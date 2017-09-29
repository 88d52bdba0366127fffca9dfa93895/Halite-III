"""
User hackathon API endpoints - list user's hackathons & associate to new ones
"""

import flask
import sqlalchemy

from .. import model, util

from . import util as api_util
from .blueprint import web_api


@web_api.route("/user/<int:intended_user>/hackathon", methods=["GET"])
@util.cross_origin(methods=["GET", "POST"])
@api_util.requires_login(accept_key=True)
def get_user_hackathons(intended_user, *, user_id):
    if user_id != intended_user:
        raise api_util.user_mismatch_error()

    record = []
    with model.engine.connect() as conn:
        hackathons = conn.execute(sqlalchemy.sql.select([
            model.hackathons.c.id,
            model.hackathons.c.title,
            model.hackathons.c.start_date,
            model.hackathons.c.end_date,
            model.hackathons.c.location,
            model.hackathons.c.thumbnail,
            model.hackathons.c.description,
            model.hackathons.c.is_open,
        ]).select_from(
            model.hackathon_participants.join(
                model.hackathons,
                model.hackathons.c.id == model.hackathon_participants.c.hackathon_id
            )
        ).where(
            model.hackathon_participants.c.user_id == intended_user
        )).fetchall()

        for hackathon in hackathons:
            record.append({
                "hackathon_id": hackathon["id"],
                "title": hackathon["title"],
                "status": api_util.hackathon_status(hackathon["start_date"],
                                                    hackathon["end_date"]),
                
                "start_date": hackathon["start_date"],
                "end_date": hackathon["end_date"],
                "location": hackathon["location"],
                "thumbnail": hackathon["thumbnail"],
                "description":hackathon["description"],
                "is_open":hackathon["is_open"],
                "participant": True
            })

        open_hackathons = conn.execute(sqlalchemy.sql.select([
            model.hackathons.c.id,
            model.hackathons.c.title,
            model.hackathons.c.start_date,
            model.hackathons.c.end_date,
            model.hackathons.c.location,
            model.hackathons.c.thumbnail,
            model.hackathons.c.description,
        ]).where(
            model.hackathons.c.is_open == 1
        )).fetchall()

        for hackathon in open_hackathons:
            if not any(userHackathon["hackathon_id"] == hackathon["id"] for userHackathon in record):
                record.append({
                    "hackathon_id": hackathon["id"],
                    "title": hackathon["title"],
                    "status": api_util.hackathon_status(hackathon["start_date"],
                                                        hackathon["end_date"]),
                    
                    "start_date": hackathon["start_date"],
                    "end_date": hackathon["end_date"],
                    "location": hackathon["location"],
                    "thumbnail": hackathon["thumbnail"],
                    "description":hackathon["description"],
                    "is_open":hackathon["is_open"],
                    "participant": False,
                })
    
    return flask.jsonify(record)


@web_api.route("/user/<int:intended_user>/hackathon", methods=["POST"])
@util.cross_origin(methods=["GET", "POST"])
@api_util.requires_login(accept_key=False)
@api_util.requires_competition_open
def associate_user_hackathon(intended_user, *, user_id):
    if user_id != intended_user:
        raise api_util.user_mismatch_error()

    verification_code = flask.request.form.get("verification_code")
    if not verification_code:
        raise util.APIError(
            400,
            message="Please provide the verification code."
        )

    with model.engine.connect() as conn:
        hackathon = conn.execute(model.hackathons.select(
            model.hackathons.c.verification_code == verification_code)).first()

        if not hackathon:
            raise util.APIError(
                404,
                message="Hackathon does not exist. Please check the "
                        "verification code. "
            )

        status = api_util.hackathon_status(hackathon["start_date"],
                                           hackathon["end_date"])

        if status == "closed":
            raise util.APIError(
                400,
                message="Sorry, this hackathon has already ended."
            )

        if hackathon["organization_id"] is not None:
            user = conn.execute(model.users.select().where(
                model.users.c.id == user_id
            )).first()
            if hackathon["organization_id"] != user["organization_id"]:
                raise util.APIError(
                    400,
                    message="Sorry, this hackathon is only open to members "
                            "of a certain organization. "
                )

        already_exists = conn.execute(
            model.hackathon_participants.select(
                (model.hackathon_participants.c.hackathon_id == hackathon["id"]) &
                (model.hackathon_participants.c.user_id == user_id)
            )
        ).first()

        if already_exists:
            return util.response_success({
                "message": "You're already signed up for this hackathon!"
            })

        conn.execute(
            model.hackathon_participants.insert().values(
                hackathon_id=hackathon["id"],
                user_id=user_id,
            )
        )

    return util.response_success()
