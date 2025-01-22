package presets;
var ca: ControllerAccess<GameAction>;

var name = default;

public static var jump = ca.ispressed(jump) && ca.keyispressed(K.A);

public static var dash = ca.() && ca.keyispressed(Key.Shift);