import logging.config
from typing import Any

LOGGING_CONFIG: dict[str, Any] = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "standard": {
            "format": f"[\033[1m\033[94m%(levelname)s\033[0m] %(message)s"
        }
    },
    "handlers": {
        "default": {
            "class": "logging.StreamHandler",
            "formatter": "standard",
            "level": "DEBUG",
            "stream": "ext://sys.stdout"
        }
    },
    "loggers": {
        "": {
            "handlers": ["default"],
            "level": "INFO",
            "propagate": False
        },
        "__main__": {
            "handlers": ["default"],
            "level": "DEBUG",
            "propagate": False
        },
        "pom8_parser": {
            "handlers": ["default"],
            "level": "DEBUG",
            "propagate": False
        }
    }
}

logging.config.dictConfig(LOGGING_CONFIG)