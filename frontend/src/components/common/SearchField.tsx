import { Ionicons } from '@expo/vector-icons';
import { useEffect, useState } from 'react';
import { Pressable, StyleSheet, TextInput, View } from 'react-native';
import { colors, spacing } from '../../theme';

type Props = {
  value: string;
  onChangeText: (text: string) => void;
  placeholder?: string;
  debounceMs?: number;
};

export function SearchField({
  value,
  onChangeText,
  placeholder = 'Search…',
  debounceMs = 300,
}: Props) {
  const [local, setLocal] = useState(value);
  const [isFocused, setIsFocused] = useState(false);

  useEffect(() => {
    setLocal(value);
  }, [value]);

  useEffect(() => {
    const t = setTimeout(() => onChangeText(local), debounceMs);
    return () => clearTimeout(t);
  }, [local, debounceMs, onChangeText]);

  const handleClear = () => {
    setLocal('');
    onChangeText('');
  };

  return (
    <View style={[styles.container, isFocused && styles.containerFocused]}>
      <Ionicons
        name="search"
        size={18}
        color={isFocused ? colors.primary : colors.textMuted}
        style={styles.icon}
      />
      <TextInput
        style={styles.input}
        value={local}
        onChangeText={setLocal}
        placeholder={placeholder}
        placeholderTextColor={colors.textMuted}
        onFocus={() => setIsFocused(true)}
        onBlur={() => setIsFocused(false)}
        autoCapitalize="none"
        autoCorrect={false}
      />
      {local.length > 0 && (
        <Pressable onPress={handleClear} hitSlop={8}>
          <Ionicons name="close-circle" size={18} color={colors.textMuted} />
        </Pressable>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 12,
    paddingHorizontal: spacing.md,
    paddingVertical: 10,
    marginBottom: spacing.md,
  },
  containerFocused: {
    borderColor: colors.primary,
  },
  icon: {
    marginRight: spacing.sm,
  },
  input: {
    flex: 1,
    fontSize: 15,
    color: colors.text,
    padding: 0,
  },
});
