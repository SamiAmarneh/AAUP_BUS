import { initializeApp } from "firebase-admin/app";
import { getFirestore, GeoPoint } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";

initializeApp();

const notificationTypeNewBooking = "new_booking";

interface ReservationData {
  trip_id?: FirebaseFirestore.DocumentReference;
  pickup_location?: string;
  pickup_coordinates?: GeoPoint;
  phone_number?: string;
}

interface TripData {
  driver_id?: FirebaseFirestore.DocumentReference;
  route_id?: FirebaseFirestore.DocumentReference;
  total_passengers?: number;
}

interface RouteData {
  route_name?: string;
}

interface DriverData {
  fcm_token?: string;
}

function readDocumentId(
  reference: FirebaseFirestore.DocumentReference | undefined,
): string {
  return reference?.id ?? "";
}

function readString(value: unknown, fallback = ""): string {
  return typeof value === "string" ? value.trim() : fallback;
}

function readNumber(value: unknown, fallback = 0): number {
  return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}

function maskPhoneNumber(phoneNumber: string): string {
  const trimmed = phoneNumber.trim();
  if (trimmed.length <= 4) {
    return trimmed;
  }
  return `***${trimmed.slice(-4)}`;
}

function buildNotificationBody(
  totalPassengers: number,
  pickupLocation: string,
): string {
  const passengerLabel =
    totalPassengers === 1 ? "1 passenger" : `${totalPassengers} passengers`;
  return `${passengerLabel} booked. Pickup: ${pickupLocation}`;
}

export const notifyDriverOnBooking = onDocumentCreated(
  "Reservation/{reservationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.warn("Reservation create event had no snapshot.");
      return;
    }

    const reservationId = event.params.reservationId;
    const reservation = snapshot.data() as ReservationData;
    const tripRef = reservation.trip_id;
    const pickupLocation = readString(reservation.pickup_location);

    if (!tripRef) {
      logger.warn("Reservation missing trip_id.", { reservationId });
      return;
    }

    if (!pickupLocation) {
      logger.warn("Reservation missing pickup_location.", { reservationId });
      return;
    }

    const db = getFirestore();
    const tripSnapshot = await tripRef.get();
    if (!tripSnapshot.exists) {
      logger.warn("Linked trip not found.", { reservationId, tripId: tripRef.id });
      return;
    }

    const trip = tripSnapshot.data() as TripData;
    const driverUid = readDocumentId(trip.driver_id);
    if (!driverUid) {
      logger.warn("Trip missing driver_id.", { reservationId, tripId: tripRef.id });
      return;
    }

    const routeRef = trip.route_id;
    let routeName = "Trip";
    if (routeRef) {
      const routeSnapshot = await routeRef.get();
      if (routeSnapshot.exists) {
        const route = routeSnapshot.data() as RouteData;
        routeName = readString(route.route_name, routeName);
      }
    }

    const driverSnapshot = await db.collection("drivers").doc(driverUid).get();
    if (!driverSnapshot.exists) {
      logger.warn("Driver profile not found.", { driverUid, reservationId });
      return;
    }

    const driver = driverSnapshot.data() as DriverData;
    const fcmToken = readString(driver.fcm_token);
    if (!fcmToken) {
      logger.info("Driver has no FCM token; skipping notification.", {
        driverUid,
        reservationId,
      });
      return;
    }

    const totalPassengers = readNumber(trip.total_passengers);
    const maskedPhone = maskPhoneNumber(readString(reservation.phone_number));
    const coordinates = reservation.pickup_coordinates;

    const dataPayload: Record<string, string> = {
      type: notificationTypeNewBooking,
      tripId: tripRef.id,
      reservationId,
      totalPassengers: String(totalPassengers),
      pickupLocation,
      maskedPhone,
    };

    if (coordinates instanceof GeoPoint) {
      dataPayload.pickupLat = String(coordinates.latitude);
      dataPayload.pickupLng = String(coordinates.longitude);
    }

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: `New booking — ${routeName}`,
          body: buildNotificationBody(totalPassengers, pickupLocation),
        },
        data: dataPayload,
        android: {
          priority: "high",
        },
      });
      logger.info("Driver booking notification sent.", {
        driverUid,
        reservationId,
        tripId: tripRef.id,
        totalPassengers,
      });
    } catch (error) {
      logger.error("Failed to send driver booking notification.", {
        driverUid,
        reservationId,
        error,
      });
    }
  },
);
