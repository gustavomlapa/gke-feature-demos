FROM python:3.11-alpine

WORKDIR /app

# Criar usuario sem privilegios de root para seguranca
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY server.py /app/
COPY static /app/static/

RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 8080

CMD ["python3", "-u", "server.py"]
